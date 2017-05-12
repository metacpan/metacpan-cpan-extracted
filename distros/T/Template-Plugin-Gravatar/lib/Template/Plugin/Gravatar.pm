package Template::Plugin::Gravatar;
use warnings;
use strict;
use base "Template::Plugin";
use Carp qw( carp croak );
use URI ();
use Digest::MD5 ();

our $VERSION = "0.10";
our $AUTHORITY = "cpan:ASHLEY";
our $Gravatar_Base = "https://gravatar.com/avatar/";

sub new {
    my ( $class, $context, $instance_args ) = @_;
    $instance_args ||= {}; # the USE'd object.
    my $config = $context->{CONFIG}{GRAVATAR} || {}; # from TT config.
    my %args;

    $args{default} = $instance_args->{default} || $config->{default};
    $args{rating} = $instance_args->{rating} || $config->{rating};
    $args{border} = $instance_args->{border} || $config->{border};
    $args{size} = $instance_args->{size} || $config->{size};

    # Overriding the base might be nice for some developers.
    $args{base} = $instance_args->{base} || $config->{base} ||
        $Gravatar_Base;

    return sub {
        my $args = shift || {};
        $args = {
            %args,
            %{$args}
        };
        $args->{email} || croak "Cannot generate a Gravatar URI without an email address";
        if ( $args->{size} ) {
            $args->{size} >= 1 and $args->{size} <= 2048
                or croak "Gravatar size must be 1 .. 2048";
        }
        if ( $args->{rating} ) {
            $args->{rating} =~ /\A(?:G|PG|R|X)\z/
                or croak "Gravatar rating can only be G, PG, R, or X";
        }
        if ( $args->{border} ) {
            carp "Border is deprecated! Dropping it.";
        }

        my $email = $args->{email};
        s/\A\s+//, s/\s+\z// for $email;
        $email = lc $email; # Might need to consider charset here or document consideration...
        $args->{gravatar_id} = Digest::MD5::md5_hex($email);

        my $uri = URI->new( $args->{base} || $Gravatar_Base );
        my @ordered = map { $_, $args->{$_} }
            grep $args->{$_},
            qw( gravatar_id rating size default );
        $uri->query_form(@ordered);
        $uri;
    }
}

1;

__END__

=head1 Name

Template::Plugin::Gravatar - Configurable TT2-based generation of Gravatar URLs from email addresses.

=head1 Synopsis

  [% USE Gravatar %]
  [% FOR user IN user_list %]
   <img src="[% Gravatar( email => user.email ) | html %]"
     alt="[% user.name | html %]" />
  [% END %]

  # OR a mini CGI example
  use strict;
  use CGI qw( header start_html end_html );
  use Template;

  my %config = ( # ... your other config stuff
                GRAVATAR => { default => "http://myhost.moo/local/image.png",
                              size => 80,
                              rating => "R" },
                );
  # note the "default" must be an absolute URI to work correctly

  my $tt2 = Template->new(\%config);

  my $user = { email => 'whatever@wherever.whichever',
               rating => "PG",
               name => "Manamana",
               size => 75 };

  print header(), start_html();

  $tt2->process(\*DATA, { user => $user })
      or warn $Template::ERROR;

  print end_html();

  __DATA__
  [% USE Gravatar %]
  [% FILTER html %]
   <img src="[% Gravatar( user ) | html %]"
     alt="[% user.name | html %]" />
  [% END %]

=head1 Description

Please see L<http://gravatar.com/site/implement/url> for more on the
service interface and L<http://gravatar.com/> for information
about Gravatars (globally recognized avatars) in general.

All of the options supported in GravatarsE<mdash>default, rating, and
sizeE<mdash>can be used here. The C<gravatar_id> is generated from a given
email.

=head1 Interface/Settings

=head2 new

Not called directly. Called when you C<USE> the plugin. Takes defaults
from the template config hash and mixes them with any per template
defaults. E.g.E<ndash>

  [% USE Gravatar %]
  Use config arguments if any.

  [% USE Gravatar(default => 'http://mysite.moo/local/default-image.gif') %]
  Mix config arguments, if any, with new instance arguments.

=head2 Arguments

=over 4

=item email (required)

The key to using Gravatars is a hex hash of the user's email. This is
generated automatically and sent to gravatar.com as the C<gravatar_id>.

=item default (optional)

The local (any valid absolute image URI) image to use if there is no
Gravatar corresponding to the given email.

=item size (optional)

Gravatars are square. Size is 1 through 80 (pixels) and sets the width
and the height.

=item rating (optional)

G|PG|R|X. The B<maximum> rating of Gravatar you wish returned. If you
have a family friendly forum, for example, you might set it to "G."

=item border (DEPRECATED)

A hex color, e.g. FF00FF or F0F. Gravatar no longer does anything with
these so we don't even pass them along. If included they will give a
warning.

=item base (developer override)

This is provided as a courtesy for the one or two developers who might
need it. More below.

=item gravatar_id (not allowed)

This is B<not> an option but a generated variable. It is an MD5 hex
hash of the email address. The reason is it not supported as an
optional variable is it would allow avatar hijacking.

=back

The only argument that must be given when you call the C<Gravatar>
plugin is the email. Everything elseE<mdash>rating, default image,
border, and sizeE<mdash>can be set in three different places: the
config, the C<USE> call, or the C<Gravatar> call. All three of the
following produce the same Gravatar URL.

=head2 Settings via config

Used if the entire "site" should rely on one set of defaults.

  use Template;
  my %config = (
     GRAVATAR => {
         default => "http://mysite.moo/img/avatar.png",
         rating => "PG",
         size => 80,
     }
  );

  my $template = <<;
  [% USE Gravatar %]
  [% Gravatar(email => 'me@myself.ego') | html %]
  
  my $tt2 = Template->new(\%config);
  $tt2->process(\$template);

=head2 Settings via instance

Used if a particular template needs its own defaults.

  use Template;
  my $template = <<;
  [% USE Gravatar( rating => "PG",
                   size => 80 ) %]
  [% Gravatar(email => 'me@myself.ego') | html %]
  
  my $tt2 = Template->new();
  $tt2->process(\$template);

Any other calls with different emails will share the defaults in this
template.

=head2 Settings in the Gravatar call

Used for per URL control.

  use Template;
  my $template = <<;
  [% USE Gravatar %]
  [% Gravatar(email => 'me@myself.ego',
              default => "http://mysite.moo/img/avatar.png",
              rating => "PG",
              size => 80 ) | html %]
  
  my $tt2 = Template->new();
  $tt2->process(\$template);

=head2 Base URL (for developers only)

You may also override the base URL for retrieving the Gravatars. It's
set to use the service from L<https://gravatar.com/>. It can be
overridden in the config or the C<USE>.

=head1 Diagnostics

Email is the only required argument. Croaks without it.

Rating and size are also validated on each call. Croaks if an
invalid size (like 0 or 100) or rating (like MA or NC-17).

=head1 Configuration AND ENVIRONMENT

No configuration is necessary. You may use the configuration hash of
your new template to pass default information like the default image
location for those without Gravatars. You can also set it in the C<USE>
call per template if needed.

=head1 Dependencies (see also)

L<Template>, L<Template::Plugin>, L<Carp>, L<Digest::MD5>, and
L<URI::Escape>.

L<http://gravatar.com/>

=head1 Bugs and Limitations

None known. I certainly appreciate bug reports and feedback via
L<https://github.com/pangyre/p5-template-plugin-gravatar/issues>.

=head1 Author

Ashley Pond V, C<< <ashley@cpan.org> >>.

=head1 License

Copyright 2007-2016, Ashley Pond V.

This program is free software; you can redistribute it and modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>.

=head1 See Also

L<Gravatar::URL> - standalone Gravatar URL generation.

L<http://gravatar.com> - The Gravatar web site.

L<http://gravatar.com/site/implement/> - The Gravatar URL implementation guide.

=cut
