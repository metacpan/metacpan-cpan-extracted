package Module::Provision::TraitFor::Badges;

use namespace::autoclean;

use Class::Usul::Constants qw( OK TRUE );
use Moo::Role;

requires qw( output quiet select_method stash );

around 'select_method' => sub {
   my ($orig, $self, @args) = @_; my $method = $orig->( $self, @args );

   $method eq 'get_badge_markup' and $self->quiet( TRUE );

   return $method;
};

sub get_badge_markup : method {
   my $self     = shift;
   my $s        = $self->stash;
   my $distname = $s->{distname};
   my $distdir  = $s->{lc_distname};
   my $reponame = $s->{pub_repo_prefix}.$distdir;
   my $coverage = $self->config->coverage_server;
   my $travis   = 'https://travis-ci.org/'.$s->{author_id};
   my $args     = sub { { cl => $_[ 0 ], nl => $_[ 0 ], no_lead => TRUE } };
   my $out      = sub { $self->output( $_[ 0 ], $args->( $_[ 1 ] ) ) };

   $out->( '=begin html', TRUE );
   $out->( "<a href=\"${travis}/${reponame}\">"
         . "<img src=\"${travis}/${reponame}.svg?branch=master\""
         . ' alt="Travis CI Badge"></a>' );
   $out->( "<a href=\"${coverage}/report/${distdir}/latest\">"
         . "<img src=\"${coverage}/badge/${distdir}/latest\""
         . ' alt="Coverage Badge"></a>' );
   $out->( "<a href=\"http://badge.fury.io/pl/${distname}\">"
         . "<img src=\"https://badge.fury.io/pl/${distname}.svg\""
         . ' alt="CPAN Badge"></a>' );
   $out->( "<a href=\"http://cpants.cpanauthors.org/dist/${distname}\">"
         . "<img src=\"http://cpants.cpanauthors.org/dist/${distname}.png\""
         . ' alt="Kwalitee Badge"></a>' );
   $out->( '=end html', TRUE );
   return OK;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Module::Provision::TraitFor::Badges - Generate badge markup to paste into POD

=head1 Synopsis

   use Moo;

   extends 'Module::Provision::Base';
   with    'Module::Provision::TraitFor::Badges';

=head1 Description

Generate badge markup to paste into POD

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<get_badge_markup> - Generate badge markup to paste into POD

Prints the markup for badges in POD to standard output for ease of cut and
paste

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Provision.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
