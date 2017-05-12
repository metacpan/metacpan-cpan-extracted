#
# This file is part of MooseX-Unique
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package MooseX::Unique;
BEGIN {
  $MooseX::Unique::VERSION = '0.005';
}
BEGIN {
  $MooseX::Unique::AUTHORITY = 'cpan:EALLENIII';
}

#ABSTRACT: Make your Moose instances as unique as you are
use Moose 1.9900; no Moose;  # Lazy hack for auto prereqs.
use Moose::Exporter;
use MooseX::InstanceTracking 0.06;
use MooseX::Unique::Meta::Trait::Class;
use MooseX::Unique::Meta::Trait::Attribute;
use MooseX::Unique::Meta::Trait::Role::ApplicationToClass;


Moose::Exporter->setup_import_methods(
    class_metaroles => {
        class => [
            'MooseX::InstanceTracking::Role::Class',
            'MooseX::Unique::Meta::Trait::Class'
        ],
        attribute => ['MooseX::Unique::Meta::Trait::Attribute'],
    },
    role_metaroles => {
        role      => ['MooseX::Unique::Meta::Trait::Role'],
        applied_attribute => ['MooseX::Unique::Meta::Trait::Attribute'],
        attribute => ['MooseX::Unique::Meta::Trait::Attribute'],
        application_to_class =>
            ['MooseX::Unique::Meta::Trait::Role::ApplicationToClass'],
        application_to_role =>
            ['MooseX::Unique::Meta::Trait::Role::ApplicationToRole'],
    },
    base_class_roles => ['MooseX::Unique::Meta::Trait::Object'],
    with_meta        => ['unique', 'required_matches'],

);

sub unique {
    my ( $meta, @att ) = @_;
    if ( ref $att[0] ) {
        @att = @{ $att[0] };
    }
    $meta->add_match_attribute( @att );
}

sub required_matches {
    my ( $meta, $val) = @_;
    $meta->add_match_requires( $val );
}


1;


=pod

=for :stopwords Edward Allen J. III cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders BUILDARGS params readonly
MetaRole metaroles metaclass doy Luehrs sartak UniqueIdentity

=encoding utf-8

=head1 NAME

MooseX::Unique - Make your Moose instances as unique as you are

=head1 VERSION

  This document describes v0.005 of MooseX::Unique - released June 22, 2011 as part of MooseX-Unique.

=head1 SYNOPSIS

    package MyApp;
    use Moose;
    use MooseX::Unique;

    has identity => (
        is  => 'ro',
        isa => 'Str',
        required => 1,
        unique => 1,
    );

    has number =>  ( 
        is => 'rw',
        isa => 'Int'
    );


    package main;
    use Modern::Perl;


    my $objecta = MyApp->new_or_matching(identity => 'Mine');
    my $objectb = MyApp->new_or_matching(identity => 'Mine');

    $objecta->number(40);

    # prints:  Num: 40
    say "Num: ", $objectb->number;

=head1 DESCRIPTION

This module uses L<MooseX::InstanceTracking> to keep track of your
instances.  If an attribute has a unique flag set, and a new attribute is
requested with the same value, the original will be returned.

This is useful if

=over

=item *

If you are creating several attributes from data, which may have 
duplicates that you would rather merge than replace.

=item *

If you want to create a new or modify and are too lazy to look up the data
yourself. 

=item *

You have a complicated network of data, with several cross references.
For example, a song could have an album and an artist.  That album could
have the same artist, or a different artist.  That artist can have
multiple albums.  That album, of course, has multiple songs.  When
importing song by song, this web would be lost without some sort of
instance tracking.  This module lets Moose do the work for you.

=back

That having all been said, B<think twice> before using this module.  It 
can cause spooky action at a distance.  Be sure to use it only on immutable
objects. The synopsis should indicate how this can be troubling, confusing, 
and a great source of bizarre bugs if you are not paying attention.

In addition to the spooky action at a distance, please keep in mind that the
instance tracking is performed using B<weak references>.  If you let an object
fall out of scope, it is gone, so a new object with the same unique attribute
will be new.

=head1 METHODS

=head2 new_or_matching(%params)

Provided by L<MooseX::Unique::Object|MooseX::Unique::Object>.

This is a wrapper around your new method that looks up the attribute for you.  
Please note that this module does not process your BUILDARGS before looking for 
an instance.  So, values must be passed as a hash or hash reference. Any
attribute that is not flagged as unique will be ignored in the case of an
existing instance.

=head1 FUNCTIONS

=head2 unique($attr)

Sugar method that can be used instead of attribute labeling.  Set $attr to 
the name of an attribute and it will be unique.

This can be used in a role even if the attribute is not defined in the role.

=head2 required_matches($int)

Sugar method that sets the minimum number of matches required to make a match.
The default is 1.  Setting this to 0 means that a match requires that all
attributes set to unique are matched. If you run this more than once, for
example in a role, it will add to the existing unless the existing is 0.  If
you set it to 0, it will reset it to 0 regardless of current value. 

=head1 BUGS

I'm sure there are a few in the shadows.  Please submit test cases to the bug
tracker web link above.  

=head1 ACKNOWLEDGMENTS

Thanks to Jesse (doy) Luehrs for steering me clear of bad code design.

Thanks to Shawn (sartak) Moore for L<MooseX::InstanceTracking>.

And thanks to the rest of the Moose team for L<Moose>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<MooseX::InstanceTracking|MooseX::InstanceTracking>

=back

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/MooseX-Unique>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=MooseX::Unique>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/MooseX-Unique>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/MooseX-Unique>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=MooseX-Unique>

=back

=head2 Email

You can email the author of this module at C<EALLENIII at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-moosex-unique at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Unique>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/riemann42/MooseX-Unique>

  git clone git://github.com/riemann42/MooseX-Unique.git

=head1 AUTHOR

Edward Allen <ealleniii@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edward J. Allen III.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__


