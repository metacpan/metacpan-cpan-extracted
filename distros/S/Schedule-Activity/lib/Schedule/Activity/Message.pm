package Schedule::Activity::Message;

use strict;
use warnings;
use Ref::Util qw/is_arrayref is_hashref is_ref/;

our $VERSION='0.1.1';

my %property=map {$_=>undef} qw/message attributes note/;

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		attributes=>$opt{attributes}//{},
		msg       =>[],
	);
	if(is_hashref($opt{message})&&is_arrayref($opt{message}{alternates})) { @{$self{msg}}=grep {is_hashref($_) && !is_ref($$_{message}) && defined($$_{message})} @{$opt{message}{alternates}} }
	elsif(is_arrayref($opt{message})) { @{$self{msg}}=grep {!is_ref($_) && defined($_)} @{$opt{message}} }
	elsif(!is_ref($opt{message}))     { @{$self{msg}}=grep {!is_ref($_) && defined($_)} $opt{message} }
	return bless(\%self,$class);
}

sub unwrap {
	my ($msg)=@_;
	if(!defined($msg)) { return ('',undef) }
	if(!is_ref($msg))  { return ($msg,undef) }
	if(is_hashref($msg)) { return ($$msg{message},$msg) }
	return ('',$msg);
}

sub primary { my ($self)=@_; return unwrap($$self{msg}[0]) }
sub random  { my ($self)=@_; return unwrap($$self{msg}[ int(rand(1+$#{$$self{msg}})) ]) }

1;

__END__

=pod

=head1 NAME

Schedule::Activity::Message - Container for individual or multiple messages

=head1 SYNOPSIS

	my $message=Schedule::Activity::Message->new(
		message   =>'string message',
		message   =>['array', 'of', 'alternates'],
		message   =>{
			alternates=>[
				{message=>'string', attributes=>{...}},
				{message=>'string', attributes=>{...}},
				...
			],
		}
		attributes=>{...} # optional
		note      =>...   # optional
	);

=cut
