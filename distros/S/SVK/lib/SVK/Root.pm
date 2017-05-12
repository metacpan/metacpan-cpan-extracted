# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::Root;
use strict;
use warnings;

use base qw{ Class::Accessor::Fast };

__PACKAGE__->mk_accessors(qw(root txn pool cleanup_pid));

sub AUTOLOAD {
    my $func = our $AUTOLOAD;
    $func =~ s/^.*:://;
    return if $func =~ m/^[A-Z]+$/;

    no strict 'refs';
    no warnings 'redefine';

    *$func = sub {
        my $self = shift;
        my $path = shift;
        $path = $path->stringify if index(ref($path), 'Path::Class') == 0;
        # warn "===> $self $func: ".join(',',@_).' '.join(',', (caller(0))[0..3])."\n";
        unshift @_, $path if defined $path;
        return $self->root->$func(@_);
    };

    goto &$func;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{createdby} = join(' ', (caller(2))[0..2]);
    return $self;
}

sub DESTROY {
    return unless $_[0]->txn;
    # if this destructor is called upon the pool cleanup which holds the
    # txn also, we need to use a new pool, otherwise it segfaults for
    # doing allocation in a pool that is being destroyed.
    $_[0]->txn->abort( SVN::Pool->new )
        if ( $_[0]->cleanup_pid || $$ ) == $$;
}

# return the root and path on the given revnum, the returned path is
# with necessary translations.
sub get_revision_root {
    my $self = shift;
    my $path = shift;
    return ( $self->new({root => $self->fs->revision_root(@_)}), 
	     $path );
}

sub txn_root {
    my ($self, $pool) = @_;
    my $txn = $self->fs->begin_txn($self->revision_root_revision, $pool);
    return $self->new({ txn => $txn, root => $txn->root($pool), cleanup_pid => $$ });
}

sub same_root {
    my ($self, $other) = @_;
    return 1 if $self eq $other;
    return unless ref($self) eq __PACKAGE__ && ref($other) eq __PACKAGE__;
    if ($self->txn) {
	return $other->txn ? $self->txn->name eq $other->txn->name : 0;
    }
    return $self->revision_root_revision == $other->revision_root_revision;
}

1;
