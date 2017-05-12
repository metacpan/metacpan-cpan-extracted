package Template::Plugin::HTML::SuperForm;

use strict;

use HTML::SuperForm;
use base 'Template::Plugin';

our $VERSION = 1.0;

sub new {
    my $class = shift;
    my $context = shift;

    my $arg = shift;

    unless(defined($arg)) {
        for my $key (keys %{$context->{STASH}}) {
            my $value = $context->{STASH}{$key};
            if(UNIVERSAL::isa($value, 'Apache') ||
                UNIVERSAL::isa($value, 'CGI')) {
                $arg = $value;
            }
        }
    }

    return HTML::SuperForm->new($arg, @_);
}

1;

=head1 NAME

Template::Plugin::HTML::SuperForm - Template Plugin for HTML::SuperForm

=head1 SYNOPSIS

 [% USE form = HTML.SuperForm %]
 [% form.text(name => 'my_text', default => 'default text') %]

=head1 DESCRIPTION

This is an interface into HTML::SuperForm through the Template Toolkit.
When created without arguments (i.e. [% USE form = HTML.SuperForm %]),
the Template's stash is searched for an Apache object or a CGI object
to pass to HTML::SuperForm's constructor.

When created with arguments (i.e. [% USE form = HTML.SuperForm(arg) %]),
the arguments are passed to HTML::SuperForm's constructor.


=head1 USES

With mod_perl:
   
    myHandler.pm:
    package myHandler;

    use Apache::Constants qw(OK);
    use Template;

    sub handler {
        my $r = shift;

        my $tt = Template->new();

        $r->content_type('text/html');
        $r->send_http_header();

        $tt->process('my_template.tt', { r => $r });

        return OK;
    }

    my_template.tt:
    [% USE form = HTML.SuperForm %]
    <html>
    <body>
        [% form.start_form(name => 'my_form') %]
        [% form.text(name => 'my_text', default => 'default text') %]
        [% form.submit %]
        [% form.end_form %]
    </body>
    </html>

With CGI:
   
    cgi-script:
    use Template;

    print "Content-Type: text/html\n\n";
    my $tt = Template->new();
    $tt->process('my_template.tt');

    my_template.tt:
    [% USE CGI %]
    [% USE form = HTML.SuperForm %]
    <html>
    <body>
        [% form.start_form(name => 'my_form') %]
        [% form.text(name => 'my_text', default => 'default text') %]
        [% form.submit %]
        [% form.end_form %]
    </body>
    </html>

Without CGI or mod_perl:
   
    cgi-script:
    use Template;

    print "Content-Type: text/html\n\n";
    my $tt = Template->new();
    $tt->process('my_template.tt');

    my_template.tt:
    [% USE form = HTML.SuperForm %]
    <html>
    <body>
        [% form.start_form(name => 'my_form') %]
        [% form.text(name => 'my_text', default => 'default text') %]
        [% form.submit %]
        [% form.end_form %]
    </body>
    </html>

=head1 SEE ALSO

HTML::SuperForm

=head1 AUTHOR

John Allwine E<lt>jallwine86@yahoo.comE<gt>

=cut
