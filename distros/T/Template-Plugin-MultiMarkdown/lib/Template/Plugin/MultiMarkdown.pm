package Template::Plugin::MultiMarkdown;

use warnings;
use strict;

our $VERSION = "0.12";

use vars qw($text_mmd_class);
use parent qw (Template::Plugin::Filter);
use Carp;

BEGIN {
    $text_mmd_class = 'Text::MultiMarkdown::XS';
    eval 'require Text::MultiMarkdown::XS';
    if ($@) {
        $text_mmd_class = 'Text::MultiMarkdown';
        eval 'require Text::MultiMarkdown';
        if ($@) {
            croak "cannot load either Text::MultiMarkdown::XS or Text::MultiMarkdown";
        }
    }
}
    
sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}->[0] || 'multimarkdown');
    return $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    my $options   = { %{$self->{_CONFIG}}, %{$config || {}} };
    my $req_class = delete $options->{implementation} || '';

    if ($req_class eq 'PP') {
        require Text::MultiMarkdown;
        return Text::MultiMarkdown->new(%$options)->markdown($text);
    } elsif ($req_class eq 'XS') {
        require Text::MultiMarkdown::XS;
        return Text::MultiMarkdown::XS->new($options)->markdown($text);
    } else {
    	return $text_mmd_class->new(%$options)->markdown($text);
    }
}

1;

__END__

=head1 NAME

Template::Plugin::MultiMarkdown - TT plugin for Text::MultiMarkdown

=head1 SYNOPSIS

  [% USE MultiMarkdown -%]
  [% FILTER multimarkdown %]
  #Foo
  Bar
  ---
  *Italic* blah blah
  **Bold** foo bar baz
  [%- END %]

  [% USE MultiMarkdown(implementation => 'XS') -%]
  [% FILTER multimarkdown( document_format => 'complete' ) %]
  ...
  [% END %]


=head1 DESCRIPTION

C<Template::Plugin::MultiMarkdown> wraps C<Text::MultiMarkdown::XS> and
C<Text::MultiMarkdown> into a Template Toolkit plugin, and will filter your MultiMarkdown
text into HTML.  By default the plugin will select the XS implementation over the pure
perl version, but the implementation can be chosen explictly by specifying a parameter
C<implementation> to the USE or FILTER statements.

NOTE: C<Text::MultiMarkdown::XS> is a new module and the interface to that module is still
liable to change.


=head1 SUBROUTINES/METHODS

There are two methods required by the TT plugin API:

=over 4

=item C<init()>

=item C<filter()>

=back

=head1 SEE ALSO

L<Template>, L<Text::MultiMarkdown>, L<http://fletcherpenney.net/multimarkdown/>

=head1 DEDICATION

This distribution was originally created by Andrew Ford. Sadly in early 2014,
Andrew was diagnosed with Pancreatic Cancer and passed away peacfully at home
on 25th April 2014.

One of his wishes was for his OpenSource work to continue. At his funeral, many
of his colleagues and friends, spoke of how he felt like a person of the world, 
and how he embrace the idea of OpenSource being for the benefit of the world.

Anyone wishing to donate in memory of Andrew, please consider the following
charities:

=over

=item Dignity in Dying - L<http://www.dignityindying.org.uk/>

=item Marie Curie Cancer Care - L<http://www.mariecurie.org.uk/>

=back

=head1 AUTHOR

  Original Author:    Andrew Ford               2006-2014
  Current Maintainer: Barbie <barbie@cpan.org>  2014-2015

=head1 ACKNOWLEDGEMENTS

Andrew Ford based this module on the L<Template::Plugin::Markdown> TT plugin
by Naoya Ito E<lt>naoya@bloghackers.netE<gt>.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008-2014 Andrew Ford
Copyright (C) 2014-2015 Barbie for Miss Barbell Productions.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
