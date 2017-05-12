package Finance::Bank::PNC;
use strict;
use Carp;
our $VERSION = '0.01';
use WWW::Mechanize;
use HTML::TokeParser;

sub check_PNC_balance {
	my ( $class, %opts ) = @_;
	my @accounts;
	croak "Must provide a user id"  unless exists $opts{userId};
	croak "Must provide a password" unless exists $opts{password};

	my $self = bless {%opts}, $class;
	my $mech = WWW::Mechanize->new();
	$mech->agent_alias('Windows Mozilla');
	$mech->cookie_jar( HTTP::Cookies->new() );

	$mech->post(
		'https://www.onlinebanking.pnc.com/alservlet/ValidateUserIdServlet',
		{ hiddenAcctLetter => 'p', origin => 'p', userId => $opts{userId} }
	) or die "$!";
	
	#Security Question
	my $stream = HTML::TokeParser->new( \$mech->content() ) or die "$!";
	$stream->get_tag('table');
	$stream->get_tag('tr');
	$stream->get_tag('tr');
	$stream->get_tag('td');
	$stream->get_tag('td');
	print $stream->get_trimmed_text('/td'), "\n";
	my $answer = <>;

	$mech->post(
		'https://www.onlinebanking.pnc.com/alservlet/SigninChallengeServlet',
		{
			counter               => 0,
			challengeErrorCounter => 0,
			bindDevice            => 'no',
			answer                => $answer
		}
	) or die "$!";
	
	$mech->post(
		'https://www.onlinebanking.pnc.com/alservlet/VerifyPasswordServlet',
		{
			counter              => 0,
			passwordErrorCounter => 0,
			oldUserId            => 12345,
			password             => $opts{password}
		}
	) or die "$!";

	#Scraping account page
	$stream = HTML::TokeParser->new( \$mech->content() ) or die "$!";
	$stream->get_tag('table');
	$stream->get_tag('tr');
	while ( my $token = $stream->get_tag("tr") ) {
		$token = $stream->get_tag("td");
		last if ( $token->[1]{class} and $token->[1]{class} eq 'col213' );
		$stream->get_tag("td");
		my $type = $stream->get_trimmed_text("/td");
		$stream->get_tag("td");
		my $number = $stream->get_trimmed_text("/td");
		$stream->get_tag("td");
		my $balance = $stream->get_trimmed_text("/td");
		$stream->get_tag("td");
		my $available = $stream->get_trimmed_text("/td");
		push @accounts,
		  {
			type      => $type,
			account   => $number,
			balance   => $balance,
			available => $available
		  };
	}
	return @accounts;
}
1;
__END__

=head1 NAME

Finance::Bank::PNC - Check your PNC bank accounts from Perl

=head1 SYNOPSIS

  use Finance::Bank::PNC;
  my @PNCAccounts = Finance::Bank::PNC->check_PNC_balance(
      userId  => "xxxxx",
      password => "xxxxx",
  );

  foreach (@PNCAccounts) {
  	printf "%-9s: %s | Balance: %7s | Available: %s\n",
  	$_->{type}, $_->{account}, $_->{balance}, $_->{available};
  }

=head1 DESCRIPTION

This module provides a rudimentary interface to the PNC online banking system 
at C<https://www.onlinebanking.pnc.com/alservlet/OnlineBankingServlet>
which is where C<https://www.pnc.com/webapp/unsec/Homepage.do> redirects to.

=head1 DEPENDENCIES

This module depends on C<WWW::Mechanize> and C<HTML::TokeParser>.

=head1 CLASS METHODS

    check_PNC_balance(userId => $u, password => $p)

Return an array of account hashes, one for each of your bank accounts.

=head1 ACCOUNT HASH KEYS

    $ac->type
    $ac->number
    $ac->balance
    $ac->available

Returns the account name, account number, real balance and available
balance which includes overdraft/creditlines.

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Leon Cowle C<Finance::Bank::ABSA> as this code is based upon his which
was based upon the following people's code.

Chris Ball for C<Finance::Bank::HSBC>, upon which a lot of this code is
based. Also to Simon Cozens for C<Finance::Bank::LloydsTSB>, upon which
most of C<Finance::Bank::HSBC> is based, Andy Lester (and Skud, by continuation)
for WWW::Mechanize, Gisle Aas for HTML::TokeParser.

=head1 AUTHOR

Dylan Armstrong C<dylanarmstrong116@gmail.com>

=cut
