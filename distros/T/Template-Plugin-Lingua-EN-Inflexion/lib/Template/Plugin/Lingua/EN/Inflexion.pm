#
#===============================================================================
#
#         FILE: Inflexion.pm
#
#  DESCRIPTION: Glue for Lingua::EN::Inflexion
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: See code
#      CREATED: 13/08/19 16:56:03
#     REVISION: ---
#===============================================================================
package Template::Plugin::Lingua::EN::Inflexion;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Template::Plugin';
use Lingua::EN::Inflexion 0.001008 'inflect';

sub new {
	my ($class, $context) = @_;

	my $filter_factory = sub {
		shift;
		return sub {
			tt_inflect (@_);
		};
	};

	# plugin without options can be static
	my $plugin = \&tt_inflect;

	# now define the filter and return the plugin
	$context->define_filter ('inflect', [ $filter_factory => 1 ]);
	return bless $plugin, $class;
}

sub tt_inflect {
	my $out = inflect (join ('', @_));
	return $out;
}

sub noun     { shift; return Lingua::EN::Inflexion::noun     (shift);  }
sub verb     { shift; return Lingua::EN::Inflexion::verb     (shift);  }
sub adj      { shift; return Lingua::EN::Inflexion::adj      (shift);  }
sub wordlist { shift; return Lingua::EN::Inflexion::wordlist (@_);     }

1;

__END__

=pod

=encoding utf8

=head1 NAME

Template::Plugin::Lingua::EN::Inflexion - Interface to Lingua::EN::Inflexion module

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Template;
  
  my $tsrc = <<'EOT';
  [% USE infl = Lingua.EN.Inflexion; -%]
  [% FOR obj IN objects; -%]
  [% FOR n IN [0, 1, 2]; -%]
  [% FILTER inflect; -%]
    <#d:$n>There <V:was> <#n:$n> <N:$obj.name>.
  [% IF n > 0 %]  <A:This> <N:$obj.name> <V:was> ${obj.colour}.
  [% END; END; END %]
  [% END; -%]
  EOT
  
  my $data = {
    objects => [
        { name => 'dog', colour => 'brown' },
        { name => 'goose', colour => 'white' },
        { name => 'fish', colour => 'gold' }
    ]
  };
  
  my $template = Template->new ({INTERPOLATE => 1});
  $template->process (\$tsrc, $data);

=head1 DESCRIPTION

The Lingua::EN::Inflexion Plugin is an interface to Damian Conway's
Lingua::EN::Inflexion Perl module, which provides plural inflections,
"a"/"an" selection for English words, and manipulation of numbers as words.
The plugin provides an 'inflect' filter, which can be used to
interpolate inflections in a string.

For the full gory details of the inflection functionality refer to the
L<Lingua::EN::Inflexion> manual.

=head1 METHODS

=head2 new

    my $infl = Template::Plugin::Lingua::EN::Inflexion->new ($context);

The constructor takes one argument which is the context on which the
filter will be defined and returns the new object. You will not need to
call this explicitly within a template, just USE the plugin as normal:

    [% USE infl = Lingua.EN.Inflexion; -%]

=head2 noun

    my $plural = $infl->noun ('dog')->plural;

The noun method is a wrapper around C<Lingua::EN::Inflexion::noun()> and
returns an object of L<Lingua::EN::Inflexion::Noun>.

=head2 verb

    my $plural = $infl->verb ('dog')->plural;

The verb method is a wrapper around C<Lingua::EN::Inflexion::verb()> and
returns an object of L<Lingua::EN::Inflexion::Verb>.

=head2 adj

    my $plural = $infl->adj ('canine')->plural;

The adj method is a wrapper around C<Lingua::EN::Inflexion::adj()> and
returns an object of L<Lingua::EN::Inflexion::Adj>.

=head2 wordlist

    my $list = $class->wordlist (@fruits);

The wordlist method is a wrapper around C<Lingua::EN::Inflexion::wordlist()>
and returns a scalar string.

=head1 INTERNAL METHODS

=over 4

=item C<tt_inflect ($string)>

The underlying inflect filter.

=back

=head1 SEE ALSO

L<Lingua::EN::Inflexion>, L<Template>, L<Template::Plugin>,
L<Template::Plugin::Lingua::EN::Inflect>

=head1 AUTHOR

Written and maintained by Pete Houston.

=head1 ACKNOWLEDGEMENTS

This module was inspired by and borrows very heavily from
L<Template::Plugin::Lingua::EN::Inflect>, originally written by Andrew
Ford and maintained by Barbie.

Damian Conway E<lt>damian@conway.orgE<gt> wrote the
L<Lingua::EN::Inflexion> module, which does all the heavy lifting.

=head1 COPYRIGHT & LICENSE

Parts of C<Template::Plugin::Lingua::EN::Inflect> retained here are

=over

Copyright © 2005-2014 Andrew Ford

Copyright © 2014-2015 Barbie for Miss Barbell Productions

=back

Other works are

=over

Copyright © 2019-2020 Pete Houston

=back

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut

