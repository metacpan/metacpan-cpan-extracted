package SpamMonkey::Config;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

SpamMonkey::Config - Read SpamMonkey configuration files

=head1 SYNOPSIS

  use SpamMonkey::Config;
  my $conf = SpamMonkey::Config->new();
  $conf->read("foo.cf");

=head1 DESCRIPTION

SpamMonkey configuration files look suspiciously similar to SpamAssassin
configuration files; with the current exception of conditionals, meta
rules and certain DNSBL rules, which are not supported.

SpamMonkey however does require a C<00default.cf> to set defaults; they
are not hard-coded.

=cut

sub new { my $class = shift; bless {}, $class; }

sub mylang { "en" }

sub read {
    my ($self, $file) = @_;
    open my $in, $file or die "Can't open $file: $!";
    $self->{file} = $file;
    while (<$in>) { $self->parse_line($_) }
    delete $self->{file};
}

sub parser_package { "SpamMonkey::Config::Parser" }

sub parse_line {
    my ($self, $line) = @_;
    $self->{pp} ||= $self->parser_package;
    $line =~ s/(?<!\\)#.*$//; # remove comments
    $line =~ s/^\s+//;  # remove leading whitespace
    $line =~ s/\s+$//;  # remove tailing whitespace
    return unless($line); # skip empty lines
    #warn "Parsing $line";

    $self->{line} = $line;
    my($key, $value) = split(/\s+/, $line, 2);
    $key = lc $key;
    # convert all dashes in setting name to underscores.
    $key =~ s/-/_/g;
    if ($key eq "ifplugin" or $key eq "if" or $key eq "endif") {
        return;  # XXX don't support conditionals
    } elsif ($key eq "include") { 
        die "Include $value";
    } elsif ($key !~ /^_/ and my $code = $self->{pp}->can($key)) {
        $code->($self->{pp},$self, ($value||""));
    } else {
        if (exists $self->{settings}{$key}) {
            # This may be unsound
            if (ref $self->{settings}{$key}) {
                push @{$self->{settings}{$key}}, $value;
            } else {
                $self->{settings}{$key} = [$self->{settings}{$key}, $value ];
            }
        } else { 
            $self->{settings}{$key} = $value;
        }
    }
    delete $self->{line};
}

sub die {
    my ($self, $mess) = @_;
    die "Couldn't parse line $.\n<$self->{line}>\n in $self->{file}: $mess\n";
}

package SpamMonkey::Config::Parser;

sub _split_params {
    my ($class, $conf, $value, $params) = @_;
    my ($key) = (caller(1))[3];
    $key =~ s/.*:://;
    my @values = split(/\s+/, $value, $params);
    if (@values != $params) {
        $conf->die("Missing value for '$key' directive");
    }
    @values;
}
    
sub require_version {};

sub compile_rule {
    my ($class, $conf, $rule) = @_;
    if ($rule =~ /^\// or $rule =~ s/^m(\W)/$1/) { 
        my $regexp = eval "qr${rule}o";
        $conf->die("Couldn't understand $rule: $@") if $@;
        return $regexp;
    } else { $conf->die("Malformed regexp $rule"); }
}

sub _body {
    my ($class, $conf, $value) = @_;
    my ($type) = (caller(1))[3];
    $type =~ s/.*:://;
    #warn "Seen $type";
    if ($value =~ /^(\S+)\s+eval:(.*)$/) {
        $conf->{rules}{$type}{$1} = { op => "eval", code => $2 }
    } else {
        my ($name, $rule) = $class->_split_params($conf, $value, 2);
        my $regexp = $class->compile_rule($conf,$rule);
        $conf->{rules}{$type}{$name} = $regexp;
    }
}

sub body { shift->_body(@_) }
sub rawbody { shift->_body(@_) }
sub full { shift->_body(@_) }

sub describe {
    my ($class, $conf, $value) = @_;
    my ($name, $description) = $class->_split_params($conf, $value, 2);
    $conf->{descriptions}{$name} = $description;
}

sub test { } # That's what SpamAssassin is for (Heh, heh)

sub uri {
    my ($class, $conf, $value) = @_;
    my ($name, $rule) = $class->_split_params($conf, $value, 2);
    my $regexp = $class->compile_rule($conf,$rule);
    $conf->{rules}{uri}{$name} = $regexp;
}

sub header {
    my ($class, $conf, $value) = @_;
    my ($name, $rule) = $class->_split_params($conf, $value, 2);
    my $unset;
    if ($rule =~ s{(?:\s*\[if-unset:\s*(.*)\])?$}{}) { $unset = $1; }
    if ($rule =~ /^\s*([\w:\-_]+)\s*(=~|!~)\s*(.*)/) {
        my $regexp = $class->compile_rule($conf,$3);
        $conf->{rules}{header}{$name} = { header => $1, op => $2, re => $regexp};
        $conf->{rules}{header}{$name}{unset} = $unset if $unset;
    } elsif ($rule =~ /\s*exists:(\S+)/) {
        $conf->{rules}{header}{$name} = { header => $1, op => "exists" }
    } elsif ($rule =~ /\s*eval:(.*)/) {
        $conf->{rules}{header}{$name} = { op => "eval", code => $1 }
    } else {
        $conf->die("Couldn't parse $rule");
    }
}

sub clear_report_template        { my ($class, $conf) = @_; $conf->{settings}{report_template} = ""; }
sub clear_unsafe_report_template { my ($class, $conf) = @_; $conf->{settings}{unsafe_report_template} = ""; }
sub clear_headers                { my ($class, $conf) = @_; $conf->{settings}{headers} = {}; }

sub report        { my ($class, $conf, $value) = @_; $conf->{settings}{report_template} .= $value."\n"; }
sub unsafe_report { my ($class, $conf, $value) = @_; $conf->{settings}{unsafe_report_template} .= $value."\n"; }

sub add_header {
    my ($class, $conf, $value) = @_;
    my ($reason,$name, $thing) = $class->_split_params($conf, $value, 3);
    push @{$conf->{settings}{headers}{$reason}}, {$name => $thing};
}

sub meta { } # XXX We don't support meta rules

sub _splitter {
    my ($class, $conf, $value) = @_;
    my ($type) = (caller(1))[3];
    $type =~ s/.*:://;
    my ($name, $thing) = $class->_split_params($conf, $value, 2);
    $conf->{$type}{$name} = [ split /\s+/, $thing ];
}

sub tflags { shift->_splitter(@_) }
sub score { shift->_splitter(@_) }

sub lang {
    my ($class, $conf, $value) = @_;
    my ($lang, $thing) = $class->_split_params($conf, $value, 2);
    if ($lang eq $conf->mylang) { $conf->parse_line($thing); } 
}

sub priority {
    my ($class, $conf, $value) = @_;
    my ($name, $score) = $class->_split_params($conf, $value, 2);
    $conf->{priority}{$name} = $score;
}

sub whitelist_from_rcvd {
    my ($class, $conf, $value) = @_;
    my ($addr, $ip) = $class->_split_params($conf, $value, 2);
    push @{$conf->{whitelist_from_rcvd}}, [ $addr, $ip ];
}

sub def_whitelist_from_rcvd {
    my ($class, $conf, $value) = @_;
    my ($addr, $ip) = $class->_split_params($conf, $value, 2);
    push @{$conf->{def_whitelist_from_rcvd}}, [ $addr, $ip ];
}

=head1 AUTHOR

simon, E<lt>simon@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by simon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
