#============================================================= -*-Perl-*-
#
# Pod::POM::Node::Over
#
# DESCRIPTION
#   Module implementing specific nodes in a Pod::POM, subclassed from
#   Pod::POM::Node.
#
# AUTHOR
#   Andy Wardley   <abw@kfs.org>
#   Andrew Ford    <a.ford@ford-mason.co.uk>
#
# COPYRIGHT
#   Copyright (C) 2000, 2001 Andy Wardley.  All Rights Reserved.
#   Copyright (C) 2009 Andrew Ford.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Over.pm 89 2013-05-30 07:41:52Z ford $
#
#========================================================================

package Pod::POM::Node::Over;
$Pod::POM::Node::Over::VERSION = '2.01';
require 5.006;
use strict;
use warnings;

use parent qw( Pod::POM::Node );

our @ATTRIBS =   ( indent => 4 );
our @ACCEPT  = qw( over item begin for text verbatim code );
our $EXPECT  = 'back';

sub list_type {
    my $self = shift;
    my ($first, @rest) = $self->content;

    my $first_type = $first->type;
    return;
}


1;

=head1 NAME

Pod::POM::Node::Over - POM '=over' node class

=head1 SYNOPSIS

    use Pod::POM::Nodes;

=head1 DESCRIPTION

This class implements '=over' Pod nodes.  As described by the L<perlpodspec> man page =over/=back regions are
used for various kinds of list-like structures (including blockquote paragraphs).

  =item 1.

ordered list

  =item *

  text paragraph

unordered list

  =item text

  text paragraph

definition list



=head1 AUTHOR

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt>

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2000, 2001 Andy Wardley.  All Rights Reserved.

Copyright (C) 2009 Andrew Ford.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Consult L<Pod::POM::Node> for a discussion of nodes.
