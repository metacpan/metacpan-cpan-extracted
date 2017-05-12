package Provision::Unix::VirtualOS::Xen::Config;
# ABSTRACT: perl interface to Xen configuration files
$Provision::Unix::VirtualOS::Xen::Config::VERSION = '1.08';
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        'text' => '',
        'config' => {},
      };
    bless $self, $class;
    #warn $class . sprintf( " loaded by %s, %s, %s", caller ) . "\n";
    return $self;
};

sub read_config { # pass in a filehandle, or a path to a file
    my ($self, $arg) = @_;
    my $config_fh;
    if(ref $arg eq 'GLOB'){
        open($config_fh, "<&", $arg)
            or die "Could not dup\n";
    } else {
        open($config_fh, "<", $arg)
            or die "Could not open $arg\n";
    };
    $self->{'text'} = '';
    while(<$config_fh>){
        $self->{'text'} .= $_;
    };
    $self->parse_config();
    close($config_fh);
}

sub parse_config {
    my ($self, $text) = @_;

    if(defined $text){
        $self->{'text'} = $text;
    };

    my $config = $self->{'config'};

    for(split(/\n/, $self->{'text'})){
        my @line = split(/\s+=\s+/);
        my $name = shift @line;
        my $raw_value = join(' = ', @line);
        $config->{$name} = parse_value($raw_value);
    };

};

sub clone_ref {
    my ($obj) = @_;
    my $return;
    if    ( ref $obj eq 'SCALAR' ){
            my $tmp = $$obj;
            $return = \$tmp;
    }
    elsif ( ref $obj eq 'ARRAY' ) {
        $return = [];
        for(@$obj){
            push @$return, clone_ref($_);
        };
    }
    elsif ( ref $obj eq 'HASH' ) {
            $return = {};
            for(keys %$obj){
                $return->{$_} = clone_ref($obj->{$_});
            };
    }
    else {
        $return = $obj;
    };
    return $return;
};

sub parse_value {
    my ($raw_value) = @_;
    if ( $raw_value =~ m/^\[/ ) {  #array
        my $value = $raw_value;
        $value =~ s/^\[\s*//;
        $value =~ s/\s*\]$//;
        my $values = [];
        for my $item (split(/'\s*,\s*'/, $value)){
            $item =~ s/^'//;
            $item =~ s/'$//;
            my $subconfig = parse_value($item);
            unless(defined $subconfig){
                push @{$values}, $item;
            } else {
                push @{$values}, $subconfig;
            };
        };
        return $values;
    }
    elsif ( $raw_value =~ m/^'/ ) { #string
        my $value = $raw_value;
        $value =~ s/^'//;
        $value =~ s/'$//;
        return $value;
    }
    elsif ( $raw_value =~ m/^\d/ ) { #integer
        return $raw_value;
        }
    elsif ( $raw_value =~ m/^\w+=/ ) { #hash
            my $hash_ref = {};
            for my $item (split(/\s*,\s*/, $raw_value)){
                my ($name, $value) = split(/=/, $item);
                if($value =~ m/\s+/){
                    $hash_ref->{$name} = [split(/\s+/, $value)];
                } else {
                    $hash_ref->{$name} = $value;
                }
            }
            return $hash_ref;
    }
    else {
        return;
    }
}

sub join_value {
    my ($item) = @_;
    if ( ref $item eq "" ) {
        if($item =~ /^\d+$/){
            return "$item";
        } else {
            return "'$item'"; 
        }
    }
    elsif ( ref $item eq "ARRAY" ) {
        my @processed_item;
        for(0..$#{$item}){
            push @processed_item, join_value($item->[$_]);
        };
        return "[" . join(", ", @processed_item) . "]";
    }
    elsif ( ref $item eq "HASH" ) {
        my @processed_item;
        for my $key ( keys %{$item} ){
            if(ref $item->{$key} eq 'ARRAY'){
                push @processed_item, "$key=".join(" ", @{$item->{$key}});
            } else {
                push @processed_item, "$key=$item->{$key}";
            };
        };
        return "'".join(", ", @processed_item)."'";
    }
    else {
        return;
    }
}

sub get {
    my ($self, $key) = @_;

    return clone_ref($self->{'config'}{$key});
};

sub set {
    my ($self, %new_values) = @_;

    for my $key ( keys %new_values ){
        $self->{'config'}{$key} = clone_ref($new_values{$key});
    };

    $self->update();
};

sub add_ip {
    my ($self, @ips) = @_;
    
    push @{$self->{'config'}{'vif'}[0]{'ip'}}, @ips;

    $self->update();

    return $#{$self->{'config'}{'vif'}[0]{'ip'}};
};

sub del_ip {
    my ($self, @ips) = @_;
    
    my @new_ips = ();

    for my $ip (@{$self->{'config'}{'vif'}[0]{'ip'}}){
        unless(grep(/^$ip$/, @ips)){
            push @new_ips, $ip;
        };
    };

    $self->{'config'}{'vif'}[0]{'ip'} = \@new_ips;

    $self->update();

    return $#{$self->{'config'}{'vif'}[0]{'ip'}};
};

sub get_ips {
    my ($self) = @_;

    return clone_ref($self->{'config'}{'vif'}[0]{'ip'});
};

sub clear_ips {
    my ($self) = @_;

    $self->{'config'}{'vif'}[0]{'ip'} = [];
    $self->update();
};

sub update {
    my ($self) = @_;

    $self->{'text'} = '';
    for my $key ( keys %{$self->{'config'}} ){
        my $value = join_value($self->{'config'}{$key});
        $self->{'text'} .= "$key = $value\n";
    };
};

sub write { 
    my ($self, $arg) = @_;

    my $config = $self->{'config'};

    my $CFILE;
    if(ref $arg eq 'GLOB'){
        open($CFILE, '>&', $arg) or die "Couldn't dup\n";
    } else {
        open($CFILE, '>', $arg)
            or die "Couldn't open '$arg' for writing\n";
    }
    print $CFILE $self->{'text'};
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::VirtualOS::Xen::Config - perl interface to Xen configuration files

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use Provision::Unix::VirtualOS::Xen::Config;
    my $xen_config = Provision::Unix::VirtualOS::Xen::Config->new();

    $xen_config->read('/path/to/xen_conf.cfg');

    print $xen_config->get('memory'), "\n";
    $xen_config->set('memory' => 128);
    $xen_config->add_ip('192.168.0.23');
    $xen_config->write(\*STDOUT);

=head1 DESCRIPTION

I<Provision::Unix::VirtualOS::Xen::Config> is an interface to reading and writing domU configuration files

=head1 USAGE

=head2 Provision::Unix::VirtualOS::Xen::Config->new();

This is used to instantiate a new configuration object.

=head2 $xen_config->read($file);

This will open, and parse the xen configuration object $file.

=head2 $xen_config->read(\*HANDLE);

This will read a configuration file from an open file handle.

=head2 $xen_config->parse($xen_config);

This will parse a configuration file that has been loaded into a scalar.

=head2 $xen_config->get($name);

This returns the value of the specified configuration variable. The value can
be a scalar, an array ref, or a hash ref.

=head2 $xen_config->add_ip($ip, [$ip, ...])

This will add an ip, (or list of IPs) to the configuration file.
Currently this only adds IPs to vif0.

=head2 $xen_config->del_ip($ip, [$ip, ...]);

This will delete an ip, (or list of IPs) from the configuration file.
Currently, this only deletes IPs from vif0.

=head2 $xen_config->clear_ips();

This will delete all IPs from vif0.

=head1 SUPPORT

None at the moment

=head1 AUTHOR

  Max Vohra <max@pyrodyne.biz>

=head1 COPYRIGHT

Copyright (c) Max Vohra

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
