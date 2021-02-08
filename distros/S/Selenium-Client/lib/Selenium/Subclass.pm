package Selenium::Subclass;
$Selenium::Subclass::VERSION = '1.0';
#ABSTRACT: Generic template for Selenium sugar subclasses like Selenium::Session

use strict;
use warnings;

no warnings 'experimental';
use feature qw/signatures/;


sub new ($class,$parent,$data) {
    my %lowkey;
    @lowkey{map { lc $_ } keys(%$data)} = values(%$data);
    $lowkey{parent} = $parent;

    my $self = bless(\%lowkey,$class);

    $self->_build_subs($class);
    return $self;
}

sub _request ($self, $method, %params) {

    #XXX BAD SPEC AUTHOR, BAD!
    if ( $self->{sortfield} eq 'element-6066-11e4-a52e-4f735466cecf') {
        $self->{sortfield} = 'elementid';
        $self->{elementid} = delete $self->{'element-6066-11e4-a52e-4f735466cecf'};
    }

    # Inject our sortField param, and anything else we need to
    $params{$self->{sortfield}} = $self->{$self->{sortfield}};
    my $inject = $self->{to_inject};
    @params{keys(%$inject)} = values(%$inject) if ref $inject eq 'HASH';

    # and insure it is injected into child object requests
    $params{inject} = $self->{sortfield};

    $self->{callback}->($self,$method,%params) if $self->{callback};

    return $self->{parent}->_request($method, %params);
}

sub DESTROY($self) {
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    $self->{destroy_callback}->($self) if $self->{destroy_callback};
}

#TODO filter spec so we don't need parent anymore, and can have a catalog() method
sub _build_subs($self,$class) {
    #Filter everything out which doesn't have {sortField} in URI
    my $k = lc($self->{sortfield});

    #XXX deranged field name
    $k = 'elementid' if $self->{sortfield} eq 'element-6066-11e4-a52e-4f735466cecf';

    foreach my $sub (keys(%{$self->{parent}{spec}})) {
        next unless $self->{parent}{spec}{$sub}{uri} =~ m/{\Q$k\E}/;
        Sub::Install::install_sub(
            {
                code => sub {
                    my $self = shift;
                    return $self->_request($sub,@_);
                },
                as   => $sub,
                into => $class,
            }
        ) unless $class->can($sub);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Subclass - Generic template for Selenium sugar subclasses like Selenium::Session

=head1 VERSION

version 1.0

=head1 CONSTRUCTOR

=head2 $class->new($parent Selenium::Client, $data HASHREF)

You should probably not use this directly; objects should be created as part of normal operation.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
