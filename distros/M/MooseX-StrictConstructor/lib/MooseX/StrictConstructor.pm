## no critic (Moose::RequireMakeImmutable)
package MooseX::StrictConstructor;

use strict;
use warnings;

our $VERSION = '0.21';

use Moose 0.94 ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use MooseX::StrictConstructor::Trait::Class;
use MooseX::StrictConstructor::Trait::Method::Constructor;

my %metaroles = (
    class => ['MooseX::StrictConstructor::Trait::Class'],
);

$metaroles{constructor}
    = ['MooseX::StrictConstructor::Trait::Method::Constructor']
    if $Moose::VERSION <= 1.9900;

Moose::Exporter->setup_import_methods( class_metaroles => \%metaroles );

1;

# ABSTRACT: Make your object constructors blow up on unknown attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::StrictConstructor - Make your object constructors blow up on unknown attributes

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    package My::Class;

    use Moose;
    use MooseX::StrictConstructor;

    has 'size' => ( is => 'ro' );

    # then later ...

    # this blows up because color is not a known attribute
    My::Class->new( size => 5, color => 'blue' );

=head1 DESCRIPTION

Simply loading this module makes your constructors "strict". If your
constructor is called with an attribute init argument that your class does not
declare, then it calls C<< Moose->throw_error() >>. This is a great way to
catch small typos.

=head2 Subverting Strictness

You may find yourself wanting to have your constructor accept a
parameter which does not correspond to an attribute.

In that case, you'll probably also be writing a C<BUILD()> or
C<BUILDARGS()> method to deal with that parameter. In a C<BUILDARGS()>
method, you can simply make sure that this parameter is not included
in the hash reference you return. Otherwise, in a C<BUILD()> method,
you can delete it from the hash reference of parameters.

  sub BUILD {
      my $self   = shift;
      my $params = shift;

      if ( delete $params->{do_something} ) {
          ...
      }
  }

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-strictconstructor@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

Bugs may be submitted at L<https://github.com/moose/MooseX-StrictConstructor/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for MooseX-StrictConstructor can be found at L<https://github.com/moose/MooseX-StrictConstructor>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Jesse Luehrs Karen Etheridge Ricardo Signes

=over 4

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 - 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
