package Object::Accessor::XS;

use strict;
use Carp        qw[carp];
use vars        qw[$FATAL $DEBUG $VERSION];

$VERSION    = '0.03';

use base 'Object::Accessor';

*FATAL = *Object::Accessor::FATAL;
*DEBUG = *Object::Accessor::DEBUG;

require XSLoader;
XSLoader::load('Object::Accessor::XS', $VERSION);

if ($Object::Accessor::VERSION =~ /0.0[1-3](?:_\d+)?/) {
    *Object::Accessor::DESTROY = *Object::Accessor::XS::DESTROY;
}

if ($Object::Accessor::VERSION =~ /0.0[2-3](?:_\d+)?/) {
    *Object::Accessor::_debug = *Object::Accessor::XS::_debug;
}

if ($Object::Accessor::VERSION eq '0.03') {
    *Object::Accessor::new = *Object::Accessor::XS::new;
    *Object::Accessor::mk_accessors = *Object::Accessor::XS::mk_accessors;
    *Object::Accessor::mk_flush = *Object::Accessor::XS::mk_flush;
    *Object::Accessor::ls_accessors = *Object::Accessor::XS::ls_accessors;
} else { _mismatch_exactly('0.03'); }

sub _mismatch_exactly {
    my $required = shift;
    warn "Object::Accessor::XS $Object::Accessor::XS::VERSION requires Object::Accessor $required, found $Object::Accessor::VERSION; reverting to non-XS methods.\n";
}

=head1 NAME

Object::Accessor::XS

=head1 SYNOPSIS

    ### load the XS routines
    use Object::Accessor::XS;

    ### using the object
    $object = Object::Accessor->new;        # create object

=head1 DESCRIPTION

C<Object::Accessor::XS> provides a transparent, API-compatible
interface to C<Object::Accessor>.  When loaded, it replaces
several O:A routines with their XS equivalents; you may then
continue to use C<Object::Accessor> as before.

=cut

=head1 AUTHOR

This module by
Richard Soderberg E<lt>rsod@cpan.orgE<gt>.

=head1 COPYRIGHT

This module was
copyright (c) 2004 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut

1;
