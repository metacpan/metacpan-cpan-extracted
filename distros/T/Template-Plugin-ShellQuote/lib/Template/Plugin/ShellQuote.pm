package Template::Plugin::ShellQuote;

use strict;
use String::ShellQuote;
use Template::Plugin::Filter;
use base qw(Template::Plugin::Filter);
use vars qw($VERSION $FILTER_NAME);

$VERSION = '1.3';
$FILTER_NAME = 'shellquote';


=pod

=head1 NAME

Template::Plugin::ShellQuote - provides a Template Toolkit filter to shell quote text

=head1 SYNOPSIS

    [% USE ShellQuote %]
    #!/bin/sh
    [% FILTER shellquote %]
    all this text 
    & this text 
    also *this* text
    will be quoted suitable for putting in a shell script
    [% END %]

    # this will do what you expect
    [% somevar FILTER shellquote %]

    # suitably quote stuff for a comment
    ./some_command # Some comment [% somevar FILTER shellquote (comment => 1 ) %]

=head1 DESCRIPTION

Really quite easy. Basically just provides a simple filter
so that you can easily create shell scripts using the 
Template Toolkit.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYING

(c)opyright 2003, Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty whatsoever and will probably ruin your life,
kill your friends, burn down your house and bring about the apocalypse.

=head1 BUGS

None known.

=head1 SEE ALSO

L<String::ShellQuote>, L<Template::Plugin::Filter>

=cut


sub init {
        my ($self,@args)  = @_;
        my $config = (ref $args[-1] eq 'HASH')? pop @args : {};


        $self->{_DYNAMIC} = 1;
        $self->install_filter($FILTER_NAME);

        return $self;

}

# possibly extraneous cargo culting but it works so ...
sub filter {
    my ($self, $text, @args) = @_;
    my $config = (ref $args[-1] eq 'HASH')? pop @args : {};
    
    if ($config->{comment}) {
        return shell_comment_quote $text; 
    } else {
        return shell_quote $text;
    }
}

1;

