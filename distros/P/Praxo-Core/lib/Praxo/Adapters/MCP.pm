package Praxo::Adapters::MCP;

use strict;
use warnings;
use Praxo::Errors qw(praxo_error);

sub new {
    my ($class, %args) = @_;
    return bless {
        transport => $args{transport},
        client_version => $args{client_version} // '0.4.0',
        protocol_version => $args{protocol_version} // '2024-11-05',
        connected => 0,
        closed => 0,
        negotiated_version => '',
        server_info => {},
    }, $class;
}

sub protocol_version { return $_[0]{negotiated_version} }
sub server_info { return $_[0]{server_info} }

sub start {
    my ($self) = @_;
    return $self if $self->{connected};
    my $result = $self->_request('initialize', {
        protocolVersion => $self->{protocol_version},
        capabilities => {},
        clientInfo => { name => 'praxo-core', version => $self->{client_version} },
    });
    my $version = $result->{protocolVersion} // '';
    praxo_error('MCP_HANDSHAKE', 'mcp: initialize returned no protocol version')
        if $version eq '';
    $self->{negotiated_version} = $version;
    $self->{server_info} = $result->{serverInfo} // {};
    $self->{connected} = 1;
    return $self;
}

sub list_tools {
    my ($self) = @_;
    $self->start;
    my @tools;
    my %names;
    my %seen;
    my $cursor;
    while (1) {
        my $result = $self->_request('tools/list',
            defined $cursor ? { cursor => $cursor } : {});
        for my $tool (@{ $result->{tools} // [] }) {
            my $name = $tool->{name} // '';
            praxo_error('MCP_DUPLICATE_TOOL', "mcp: duplicate tool $name")
                if $names{$name}++;
            push @tools, $tool;
        }
        $cursor = $result->{nextCursor};
        last if !defined $cursor || $cursor eq '';
        praxo_error('MCP_PAGINATION', 'mcp: repeated cursor') if $seen{$cursor}++;
    }
    return \@tools;
}

sub call_tool {
    my ($self, $name, $arguments) = @_;
    $self->start;
    my $result = $self->_request('tools/call', {
        name => $name,
        arguments => $arguments // {},
    });
    praxo_error('MCP_TOOL_ERROR', "mcp: tool $name failed")
        if $result->{isError};
    return $result->{structuredContent} if exists $result->{structuredContent};
    my @texts = map { $_->{text} // '' }
        grep { ($_->{type} // '') eq 'text' } @{ $result->{content} // [] };
    return undef if @texts == 0;
    return @texts == 1 ? $texts[0] : \@texts;
}

sub close {
    my ($self) = @_;
    $self->{closed} = 1;
    $self->{connected} = 0;
    my $transport = $self->{transport};
    if (ref($transport) && eval { $transport->can('close') }) {
        eval { $transport->close };
    }
    return;
}

sub _request {
    my ($self, $method, $params) = @_;
    praxo_error('MCP_CLOSED', 'mcp: client is closed') if $self->{closed};
    my $transport = $self->{transport};
    my $result;
    if (ref($transport) && eval { $transport->can('request') }) {
        $result = $transport->request($method, $params);
    } elsif (ref($transport) eq 'CODE') {
        $result = $transport->($method, $params);
    } else {
        praxo_error('MCP_TRANSPORT', 'mcp: transport is required');
    }
    return ref($result) eq 'HASH' ? $result : {};
}

1;
