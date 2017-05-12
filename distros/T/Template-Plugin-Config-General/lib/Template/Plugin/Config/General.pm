#============================================================= -*-Perl-*-
#
# Template::Plugin::Config::General
#
# DESCRIPTION
#   Wrapper around Config::General module
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

package Template::Plugin::Config::General;

use strict;
use vars qw( $VERSION );
use Template::Plugin;
use base qw( Template::Plugin );
use Template::Exception;
use Config::General;

$VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);

my $EXCEPTION_TYPE = 'ConfigGeneral';

sub new {
	my ( $class, $context, $options ) = @_;
	$options ||= {};
	# in template we use parameters without leading -
	map { $options->{'-' . $_} = $options->{$_} unless ( /^-/ ); } keys %$options;
	my $obj;
	eval '$obj = new Config::General( %$options )';
	$@ and die ( Template::Exception->new( $EXCEPTION_TYPE, $@ ) );
	bless {
		_CONTEXT	=> $context,
		_OBJ		=> $obj,
		_OPTIONS	=> $options,
	}, $class;
}

sub getall {
	my $self = shift;
	my %hash = $self->{_OBJ}->getall();
	return \%hash;
}

1;

__END__

=head1 NAME

Template::Plugin::Config::General - Template Toolkit plugin which implements
wrapper around Config::General module.

=head1 SYNOPSIS

  # Config file format
  ; app.cfg - common configuration for scripts and both
  ; static and dynamic template pages.
  base_url     = /~liol
  images_url   = $base_url/images
  <news>
    title      = Top News
    url        = $base_url/news
    images_url = $url/images
  </news>
  <admin>
    title      = Admin area
    url        = $base_url/admin
    images_url = $url/images
  </admin>
  include specific.cfg

  # Reading configuration from code
  use Config::General;
  $plConfig = new Config::General(
    -ConfigFile       => 'app.cfg',
    -ConfigPath       => [ '/web/etc' ]
    -InterPolateVars  => 1,
    -UseApacheInclude => 1,
  );
  my %cfg = $plConfig->getall;

  # Reading configuration from template
  [%-
    USE plConfig = Config::General(
      ConfigFile       = 'app.cfg',
      ConfigPath       = [ '/web/etc' ]
      InterPolateVars  = 1,
      UseApacheInclude = 1,
    );
    cfg = plConfig.getall;
  -%]
  [% cfg.news.title %]
  [% cfg.admin.images_url %]

=head1 DESCRIPTION

This module implements interface wrapper around
L<Config::General|Config::General>. The task of easy access
to configuration items from both code and templates may
appear in applications which uses configuration files which
are saved apart from code and templates. This module would
help to avoid data doubling. To access configuration from
code we can use Config::General module which parses
apache-like config files. This plugin makes the same thing
for templates. So we can use the same file in both code,
"dynamic" templates and "static" templates. There is no
difference what application uses template - L<ttree|ttree>
or other script. Plugin would provide proper configuration.

=head2 Interpolation

Config::General allows to make simple variable interpolation
(with constructor option B<-InterPolateVars> or in template
context B<InterPolateVars>). This can little simplify config
file support.

  base_url     = /~liol
  ; images_url = '/~liol/images'
  images_url    = $base_url/images
  <news>
    ; news->url = '/~liol/news'
    url   = $base_url/news
    ; news->images_url = '/~liol/news/images'
    images_url = $url/images
  </news>

So changing only one item of configuration you can change
all paths in file.

NOTE! Try this configuration sample for better understanding
of Config::General interpolation.

  base     = /abc
  <section>
    ; section->base = /abc/def
    base   = $base/def
    ; section->base2 = /abc/def
    base2  = $base/def
    ; section->deep = /abc/deep NOT /abc/def/deep !
    deep   = $base/deep
    ; section->deep2 = /abc/def/deep
    deep2  = $base2/deep
  </section>

This is resulting dump:

  $VAR1 = {
    'base'    => '/abc',
    'section' => {
      'base'     => '/abc/def',
      'base2'    => '/abc/def'
      'deep'     => '/abc/deep',
      'deep2'    => '/abc/def/deep',
    }
  };

=head2 Includes

Config::General allows to include in config other
configuration files.

  include external.cfg

Module searches files in set of directories defined in
constructor option B<-ConfigPath> or in template context
B<ConfigPath>. You can use this to change config in template
context.

  # Constructor call in code
  $plConfig = new Config::General(
    -ConfigFile       => 'app.cfg',
    -ConfigPath       => [ '/web/etc', '/web/etc/code' ],
    -UseApacheInclude => 1,
  );

  # Constructor call in template
  [%-
    USE plConfig = Config::General(
      ConfigFile       = 'app.cfg',
      ConfigPath       = [ '/web/etc', '/web/etc/template' ],
      UseApacheInclude = 1
    );
    cfg = plConfig.getall;
  -%]

  # Config file
  include external.cfg

Assuming that different versions of external.cfg are stored
in '/web/etc/code' and '/web/etc/template'
subdirectories we load different versions for code and
template. Of course, this can be used wider.


=head1 SEE ALSO

L<Template|Template>, L<Config::General|Config::General>

=head1 AUTHOR

Igor Lobanov, E<lt>liol@cpan.orgE<gt>

<http://www.template-toolkit.ru/>

=head1 COPYRIGHT

Copyright (C) 2005 Igor Lobanov. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
