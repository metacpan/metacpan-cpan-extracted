package Template::Plugin::Filter::I18N;

use strict;
use warnings;
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );
use Locale::gettext;
use POSIX;

our $VERSION = '0.01';

sub init {
    my ($self, @args) = @_;

	my $conf = $args[0];

	my $domain 	= $self->{_CONFIG}{domain} 	|| $conf->{domain}	|| $self->{_CONTEXT}->throw(__PACKAGE__, 'undefined domain');
	my $locale 	= $self->{_CONFIG}{locale} 	|| $conf->{locale}	|| $self->{_CONTEXT}->throw(__PACKAGE__, 'undefined locale');
	my $dir 	= $self->{_CONFIG}{dir} 	|| $conf->{dir};
	my $filter 	= $self->{_CONFIG}{filter} 	|| $conf->{filter}	|| 'i18n';
	
	setlocale(LC_MESSAGES, $locale);

	$self->{domain} = Locale::gettext->domain($domain);
	
	$self->{domain}->dir($dir);

    $self->install_filter($filter);

    return $self;
}

sub filter {
    my ($self, $text, $params) = @_;
	return $self->{domain}->get($text);
}

1;

__END__

=head1 NAME

Template::Plugin::Filter::I18N

=head1 VERSION

0.01

=head1 SYNOPSIS

	[% USE Filter.I18N %]
	[% USE Filter.I18N domain = 'my_domain' locale = 'ru_RU.UTF-8' dir = '/home/locale' filter = 'i18n' %]
	
	$context->plugin('Filter.I18N', [{domain=>'my_domain', dir=>'/home/locale', locale=>'ru_RU.UTF-8', filter=>'i18n'}]);

	[% Some text | i18n %]
	[%|i18n%]Some text[%END%]

=head1 DESCRIPTION