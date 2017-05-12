use strict;
use warnings;

package RT::Extension::ArticleTemplates;

our $VERSION = '1.01';

=head1 NAME

RT::Extension::ArticleTemplates - Turns Articles into dynamic templates
 
=head1 RT VERSION

Works with RT 4.0, 4.2 and 4.4.

=head1 DESCRIPTION

When this extension is installed, RT parses the content of Articles as a
template, when inserting the article into a ticket, using the 
L<Text::Template> module; this can be used to make your Articles dynamic.
L<Text::Template> is the same module that RT's Templates use as well.

=head1 VERY IMPORTANT

It's a B<SECURITY RISK> to install this extension on systems where
articles can be changed by not trusted users.

if your articles contain text that currently looks like a template, it
will begin being parsed as L<Text::Template> code after this extension
is installed -- even if it is not a valid template.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::ArticleTemplates');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::ArticleTemplates));

or add C<RT::Extension::ArticleTemplates> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 ArticleTemplatesWithRequestArgs

Enabling this option passes in the Mason request arguments to your article
templates as the hashref C<$request_args>.

B<Warning>: Request args are user-controlled direct input, so all the normal
cautions of using them apply.  Never trust user input.

Disabled by default.

=head1 METHODS

The following methods from L<RT::Article> are redefined:

=cut

package RT::Article;
use strict;
no warnings qw/redefine/;

=head2 ParseTemplate $CONTENT, %TEMPLATE_ARGS

Parses $CONTENT string as a template (L<Text::Template>).
$Article and other arguments from %TEMPLATE_ARGS are
available in code of the template as perl variables.

=cut

sub ParseTemplate {
    my $self = shift;
    my $content = shift;
    my %args = (
        Ticket => undef,
        @_
    );

    return ($content) unless defined $content && length $content;

    $args{'Article'} = $self;
    $args{'rtname'}  = $RT::rtname;
    if ( $args{'Ticket'} ) {
        my $t = $args{'Ticket'}; # avoid memory leak
        $args{'loc'} = sub { $t->loc(@_) };
    } else {
        $args{'loc'} = sub { $self->loc(@_) };
    }

    foreach my $key ( keys %args ) {
        next unless ref $args{ $key };
        next if ref $args{ $key } =~ /^(ARRAY|HASH|SCALAR|CODE)$/;
        my $val = $args{ $key };
        $args{ $key } = \$val;
    }

    # We need to untaint the content of the template, since we'll be working
    # with it
    $content =~ s/^(.*)$/$1/;
    my $template = Text::Template->new(
        TYPE   => 'STRING',
        SOURCE => $content
    );

    my $is_broken = 0;
    my $retval = $template->fill_in(
        HASH => \%args,
        BROKEN => sub {
            my (%args) = @_;
            $RT::Logger->error("Article parsing error: $args{error}")
                unless $args{error} =~ /^Died at /; # ignore intentional die()
            $is_broken++;
            return undef;
        },
    );
    return ( undef, $self->loc('Article parsing error') ) if $is_broken;

    return ($retval);
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-ArticleTemplates@rt.cpan.org|mailto:bug-RT-Extension-ArticleTemplates@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ArticleTemplates>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
