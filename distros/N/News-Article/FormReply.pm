# -*- Perl -*-
###########################################################################
# Written and maintained by Andrew Gierth <andrew@erlenstar.demon.co.uk>
#
# Copyright 1997 Andrew Gierth. Redistribution terms at end of file.
#
# $Id: FormReply.pm 1.5 1998/10/18 06:04:56 andrew Exp $
#

=head1 NAME

News::FormReply - derivative of News::FormArticle and News::AutoReply

=head1 SYNOPSIS

  use News::FormReply;

See below for functions available.

=head1 DESCRIPTION

This is a "mixin" of News::FormArticle and News::AutoReply; it
generates form replies by performing substitutions on a text file.

=head1 USAGE

  use News::FormReply;

Exports nothing.

=cut

package News::FormReply;

use News::FormArticle;
use News::AutoReply;
use strict;
use vars qw(@ISA);

@ISA = qw(News::FormArticle News::AutoReply);

=head1 Constructor

=over 4

=item new ( ORIGINAL, FILENAME [, SOURCE [...]] )

Construct an article as a reply to C<ORIGINAL>, initialised from the
specified file, performing variable substitution with values supplied
by the C<SOURCE> parameters (see News::FormArticle).

The Subject, To, References and In-Reply-To headers are setup B<after>
the template has been read and substituted, but a Subject header set
in a template will not be overridden.

=cut

sub new
{
    my $class = shift;
    my $src = shift;

    my $self = $class->SUPER::new(@_);
    return undef unless $self;

    $self->reply_init($src);
}

1;

__END__

###########################################################################
#
# $Log: FormReply.pm $
# Revision 1.5  1998/10/18 06:04:56  andrew
# added SYNOPSIS
#
# Revision 1.4  1997/10/22 21:01:31  andrew
# Cleanup for release.
#
# Revision 1.3  1997/08/29 00:38:19  andrew
# Doc change to reflect inherited behaviour from AutoReply
#
#
###########################################################################

=head1 AUTHOR

Andrew Gierth <andrew@erlenstar.demon.co.uk>

=head1 COPYRIGHT

Copyright 1997 Andrew Gierth <andrew@erlenstar.demon.co.uk>

This code may be used and/or distributed under the same terms as Perl
itself.

=cut

###########################################################################
