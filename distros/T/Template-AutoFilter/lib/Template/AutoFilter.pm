use strict;
use warnings;

package Template::AutoFilter;

our $VERSION = '0.143050'; # VERSION
# ABSTRACT: Template::Toolkit with automatic filtering


use base 'Template';

use Template::AutoFilter::Parser;

sub new {
    my $class = shift;

    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' ? shift : {@_};
    $params->{FILTERS}{none} ||= sub { $_[0] };

    $params->{PARSER} ||= Template::AutoFilter::Parser->new( $params );

    return $class->SUPER::new( $params );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::AutoFilter - Template::Toolkit with automatic filtering

=head1 VERSION

version 0.143050

=head1 SYNOPSIS

    use Template::AutoFilter;

    my $templ = "[% str %]  [% str | none %]  [% str | url %]";

    my $out;
    Template::AutoFilter->new->process( \$templ, { str => '<a>' }, \$out );

    print $out; # "&lt;a&gt;  <a>  %3Ca%3E"

    my $out;
    Template::AutoFilter->new( AUTO_FILTER => 'upper' )->process( \$templ, { str => '<a>' }, \$out );

    print $out; # "<A>  <a>  %3Ca%3E"

=head1 DESCRIPTION

Template::AutoFilter is a subclass of Template::Toolkit which loads a
specific Parser that is subclassed from Template::Parser. It adds a
filter instruction to each interpolation token found in templates
loaded by the TT engine. Tokens that already have a filter instruction
are left unchanged.

By default this automatic filter is set to be 'html', but can be modified
during object creation by passing the AUTO_FILTER option with the name
of the wanted filter.

Additionally a pass-through filter called 'none' is added to the object to
allow exclusion of tokens from being filtered.

Lastly, if you have problems with the directives which get auto filters
applied, you can see the L<Template::AutoFilter::Parser> docs for how you
can customize that.

WARNING: This module is highly experimental. I have not done a lot of
testing and things might blow up in unexpected ways. The API and behavior
might change with any release (until 1.0). If you'd like to see any changes
implemented, let me know via RT, email, IRC or by opening a pull request on
github.

Use at your own risk.

=head1 METHODS

=head2 new

Pre-processes the parameters passed on to Template's new(). Adds the
pass-through filter and creates the AutoFilter Parser.

All parameters passed to this new() will also be passed to the parser's
new().

=head1 CONTRIBUTORS

Ryan Olson (cpan:GIMPSON) <ryan@ziprecruiter.com>

Aran Deltac (cpan:BLUEFEET) <aran@ziprecruiter.com>

Thomas Sibley (cpan:TSIBLEY) <tsibley@cpan.org>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Template-AutoFilter>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Template-AutoFilter>

  git clone https://github.com/wchristian/Template-AutoFilter.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
