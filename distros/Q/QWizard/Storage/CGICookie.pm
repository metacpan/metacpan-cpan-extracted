package QWizard::Storage::CGICookie;

use strict;
use QWizard::Storage::Base;
our @ISA = qw(QWizard::Storage::Base);

our %cached_cookies = ();

our $VERSION = '3.15';
use CGI qw(escapeHTML);

sub new {
    my $class = shift;
    my $qw = shift;
    bless {wiz => $qw}, $class;
}

sub get {
    my ($self, $it) = @_;
    return $cached_cookies{$it} if (exists($cached_cookies{$it}));
    # XXX: optimize this
    my %cookies = fetch CGI::Cookie;
    return if (!exists($cookies{$it}));
    return $cookies{$it}->value;
}

sub get_all {
    my %cookies = fetch CGI::Cookie;
    return \%cookies;
}

sub set {
    my ($self, $it, $val) = @_;
    # security problems with passed in values.  escape them.
    my $str = "\n<script> document.cookie = \"" . escapeHTML($it) . "=" .
      escapeHTML($val) .
	"; path=/; expires=Mon, 16-Sep-2013 22:00:00 GMT\"</script>";
    $cached_cookies{$it} = $val;
    if ($self->{'started'}) {
	if ($#{$self->{'immediate_out'}}) {
	    print @{$self->{'immediate_out'}};
	    delete $self->{'immediate_out'};
	}
	print $str;
    } else {
	push @{$self->{'immediate_out'}}, $str;
    }
}

sub reset {
    # XXX: reset real cookies
    %cached_cookies = ();
}

1;

=pod

=head1 NAME

QWizard::Storage::CGICookie - Stores data in web cookies.  Requires javascript.

=head1 SYNOPSIS

  my $st = new QWizard::Storage::CGICookie();
  $st->set('var', 'value');
  $st->get('var');

=head1 DESCRIPTION

Stores data passed to it inside of web cookies.  It requires
javascript so that the cookies can be set from anywhere including
after the HTTP headers have already been sent.

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

Net-Policy: http://net-policy.sourceforge.net/

=cut
