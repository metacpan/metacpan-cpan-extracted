# $Id: Object.pm,v 1.16 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Delicious::Object;
$Net::Delicious::Object::VERSION = '1.14';

=head1 NAME 

Net::Delicious::Object - base class for Net::Delicious thingies

=head1 SYNOPSIS

 package Net::Delicious::TunaBlaster;
 use base qw (Net::Delicious::Object);

=head1 DESCRIPTION

Base class for Net::Delicious thingies. You should never access this
package directly.

=cut

sub new {
        my $pkg  = shift;
        my $args = shift;

        my @keys = keys %$args;

        my $self = bless \%{$args}, $pkg;
        $self->{'__properties'} = \@keys;

        my $class = ref($self);

        foreach my $meth (@keys) {

                if (! $self->can($meth)) {

                        no strict "refs";

                        *{ $class . "::" . $meth } = sub {
                                my $instance = shift;
                                return $instance->{$meth};
                        };
                }
        }

        return $self;
}

sub as_hashref {
        my $self = shift;
        return {$self->_mk_hash()};
}

sub _mk_hash {
        my $self = shift;

        my %hash = map {
                $_ => $self->{$_};
        } @{$self->{'__properties'}};

        return %hash;
}

=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
