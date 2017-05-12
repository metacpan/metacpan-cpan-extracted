#============================================================= -*-Perl-*-
#
# Template::Plugin::HTML::BBCode
#
# DESCRIPTION
#   Wrapper around HTML::BBCode module
#
# AUTHOR
#   Igor Lobanov <igor.lobanov@gmail.com>
#   http://www.template-toolkit.ru/
#
# COPYRIGHT
#   Copyright (C) 2005 Igor Lobanov.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::HTML::BBCode;

use strict;
use vars qw( $VERSION );
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );
use HTML::BBCode;

$VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);

# Filter name
my $DEFAULT_FILTER_NAME = 'bbcode';

# Internal hash with parsers
my $PARSERS = {};

# init defines filter name (first positional argument)
sub init {
	my $self = shift;
	$self->{_DYNAMIC} = 1;
	$self->install_filter( $self->{_ARGS}->[0] || $DEFAULT_FILTER_NAME );
	return $self;
}

sub filter {
	my ( $self, $text, undef, $conf ) = @_;
	$conf = $self->merge_config( $conf ) || {};
	# Create single BBCode object for each set of parameters - $pset
	my $pset = join('', map {
		(ref($_) eq 'HASH') ? join('', %$_) : (ref($_) eq 'ARRAY') ? join('', @$_) : $_
	} %$conf);
	my $parser = (exists $PARSERS->{$pset}) ? $PARSERS->{$pset} : $PARSERS->{$pset} = HTML::BBCode->new( $conf );
	return $parser->parse( $text );
}

1;

__END__

=head1 NAME

Template::Plugin::HTML::BBCode - Template Toolkit plugin which 
implements wrapper around HTML::BBCode module.

=head1 SYNOPSIS

  [%- USE HTML::BBCode -%]
  [% FILTER bbcode %]
  [b]BBCode[/b] - is simple [i]markup language[/i] used in
  [url=http://www.phpbb.com/]phpBB[/url].
  [% END %]

  [%- USE HTML::BBCode( 'bbcode_limited'
    allowed_tags = [ 'b', 'i', 'u' ]
  ) -%]
  [% FILTER bbcode_limited %]
  [b]BBCode[/b] - is simple [i]markup language[/i] used in
  [url=http://www.phpbb.com/]phpBB[/url].
  [% END %]

=head1 DESCRIPTION

Template::Plugin::HTML::BBCode - Template Toolkit plugin which 
implements wrapper around HTML::BBCode module and provides filter
for converting BBCode to HTML.

=head1 OPTIONS

You can pass positional and named parameters to plugin constructor

=head2 Positional parameters

The first and only positional parameter which can be passed to
constructor is new name of plugin. For example,

  [%- USE HTML::BBCode( 'bbcode_unlimited' ) -%]

This call would create BBCode-filter with name B<bbcode_unlimited>.

  [% FILTER bbcode_unlimited %] ... BBcoded text ... [% END %]

If this parameter is skipped filter name would be B<bbcode>.

=head2 Named parameters

Constructor supports named parameters B<allowed_tags>, B<html_tags>,
B<no_html>, B<linebreaks>. These parameters are passed directly to
HTML::BBCode constructor.

  [%- USE HTML::BBCode( 'bbcode_limited'
    # allow only italic, underline and bold tags
    allowed_tags = ['i','u','b']
  ) -%]
  
See L<HTML::BBCode|HTML::BBCode> for more details.

=head1 SEE ALSO

L<Template|Template>, L<HTML::BBCode|HTML::BBCode>

=head1 AUTHOR

Igor Lobanov, E<lt>liol@cpan.orgE<gt>

L<http://www.template-toolkit.ru/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Igor Lobanov. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
