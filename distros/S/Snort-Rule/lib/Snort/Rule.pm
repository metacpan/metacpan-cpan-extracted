package Snort::Rule;

=head1 NAME

Snort::Rule - Perl extension for dynamically building snort rules

=head1 SYNOPSIS

  use Snort::Rule;
  $rule = Snort::Rule->new(
  	-action	=> 'alert',
  	-proto	=> 'tcp',
  	-src	=> 'any',
  	-sport	=> 'any',
  	-dir	=> '->',
  	-dst	=> '192.188.1.1',
  	-dport	=> '44444',
  );

  $rule->opts('msg','Test Rule"');
  $rule->opts('threshold','type limit,track by_src,count 1,seconds 3600');
  $rule->opts('sid','500000');

  print $rule->string()."\n";

  OR

  $rule = 'alert tcp $SMTP_SERVERS any -> $EXTERNAL_NET 25 (msg:"BLEEDING-EDGE POLICY SMTP US Top Secret PROPIN"; flow:to_server,established; content:"Subject|3A|"; pcre:"/(TOP\sSECRET|TS)//[\s\w,/-]*PROPIN[\s\w,/-]*(?=//(25)?X[1-9])/ism"; classtype:policy-violation; sid:2002448; rev:1;)';

  $rule = Snort::Rule->new(-parse => $rule);
  print $rule->string()."\n";

=head1 DESCRIPTION

This is a very simple snort rule object. It was developed to allow for scripted dynamic rule creation. Ideally you could dynamically take a list of bad hosts and build an array of snort rule objects from that list. Then write that list using the string() method to a snort rules file.

=cut

use strict;
use warnings;

our $VERSION = '1.07';

# Put any options in here that require quotes around them
my @QUOTED_OPTIONS = ('MSG','URICONTENT','CONTENT','PCRE');

=head1 OBJECT METHODS

=head2 new

Reads in the initial headers to generate a rule and constructs the snort::rule object around it.

Accepts:

  -action => [string] ? [alert|log|pass|...] : 'alert'
  -proto => [string] ? [ip|udp|tcp|...] : 'IP'
  -src => [string] ? [$strIp] : 'any'
  -sport => [int] ? [$sport] : 'any'
  -dir => [string] ? [->|<-|<>] : '->'
  -dst => [string] ? [$strIp] : 'any'
  -dport => [int] ? [$dport] : 'any'
  -opts => [hashref] ? [hashref] : '';

  -parse => $strRule # for parsing an existing rule into the object

Returns: OBJECTREF

=cut

sub new {
	my ($class, %parms) = @_;
	my $self = {};
	bless($self,$class);
	$self->init(%parms);
	$self->parseRule($parms{-parse}) if($parms{-parse});
	return ($self);
}

# INIT

sub init {
	my ($self,%parms) = @_;
	$parms{-action} = $parms{-action} ? $parms{-action} : 'alert';
	$parms{-proto} 	= $parms{-proto} ? $parms{-proto} : 'IP';
	$parms{-src} 	= $parms{-src} ? $parms{-src} : 'any';
	$parms{-sport} 	= $parms{-sport} ? $parms{-sport} : 'any';
	$parms{-dir} 	= $parms{-dir} ? $parms{-dir} : '->';
	$parms{-dst} 	= $parms{-dst} ? $parms{-dst} : 'any';
	$parms{-dport} 	= $parms{-dport} ? $parms{-dport} : 'any';

	$parms{-opts} 	= '' if(!(ref($parms{-opts}) eq 'HASH'));

	$self->action(	$parms{-action});
	$self->proto(	$parms{-proto});
	$self->src(	$parms{-src});
	$self->sport(	$parms{-sport});
	$self->dir(	$parms{-dir});
	$self->dst(	$parms{-dst});
	$self->dport(	$parms{-dport});
	$self->opts(	$parms{-opts});
	
}

=head2 string

Outputs the rule in string form.

  print $sr->string()."\n";

Prints "options only" string:

  print $sr->string(-optionsOnly => 1)."\n";

=cut

sub string {
	my ($self,%parms) = @_;
	my $rule = '';

	$rule = $self->action().' '.$self->proto().' '.$self->src().' '.$self->sport().' '.$self->dir().' '.$self->dst().' '.$self->dport().' (' unless($parms{-optionsOnly});
	my @sort = sort { $a <=> $b } keys %{$self->opts()};
	foreach my $key (@sort) {
		if ($self->opts->{$key}->{opt}) {
           		$rule .= ' '.$self->opts->{$key}->{opt};
			$rule .= ':'.$self->opts->{$key}->{val} if($self->opts->{$key}->{val} && $self->opts->{$key}->{val} ne '""');
			$rule .= ';';
	        }
	}
	$rule .= ' )' unless($parms{-optionsOnly});
	$rule =~ s/^ // if($parms{-optionsOnly});
	return $rule;
}

=head2 action

Sets and returns the rule action [alert,log,pass,...]

  $rule->action('alert');

=cut

sub action {
	my ($self,$v) = @_;
	$self->{_action} = $v if(defined($v));
	return $self->{_action};
}

=head2 proto

Sets and returns the protocol used in the rule [tcp,icmp,udp]

  $rule->proto('tcp');

=cut

sub proto {
	my ($self,$v) = @_;
	$self->{_proto} = $v if(defined($v));
	return $self->{_proto};
}

=head2 src

Sets and returns the source used in the rule. Make sure you use SINGLE QUOTES for variables!!!

  $rule->src('$EXTERNAL_NET');

=cut

sub src {
	my ($self,$v) = @_;
	$self->{_src} = $v if(defined($v));
	return $self->{_src};
}

=head2 sport

Sets and returns the source port used in the rule

  $rule->sport(80);

=cut

sub sport {
	my ($self,$v) = @_;
	$self->{_sport} = $v if(defined($v));
	return $self->{_sport};
}

=head2 dir

Sets and returns the direction operator used in the rule, -> <- or <>

  $rule->dir('->');

=cut

sub dir {
	my ($self,$v) = @_;
	$self->{_dir} = $v if(defined($v));
	return $self->{_dir};
}

=head2 dst

Sets and returns the destination used in the rule

  $rule->dst('$HOME_NET');
  $rule->dst('192.168.1.1');

=cut

sub dst {
	my ($self,$v) = @_;
	$self->{_dst} = $v if(defined($v));
	return $self->{_dst};
}

=head2 dport

Sets and returns the destination port used in the rule

  $rule->dport(6667);

=cut

sub dport {
	my ($self,$v) = @_;
	$self->{_dport} = $v if(defined($v));
	return $self->{_dport};
}

=head2 opts

Sets an option and a value used in the rule. This currently can only be done one set at a time, and is printed in the order it was set.

  $rule->opts(option,value);
  $rule->opts('msg','this is a test rule');

This will return a hashref: $hashref->{$keyOrderValue}->{option} and $hashref->{$keyOrderValue}->{value}

  my $hashref = $rule->opts();

There is a fixQuotes() function that reads through this information before setting it, just to ensure the right options are sane. It's a very very basic function, but it seems to get the job done.

This method will also accept HASHREF's for easier use:

  $rule->opts({
  	msg 	=> 'test1',
  	rev 	=> '222',
  	content => 'Subject|3A|',
	nocase => '',
  });

  By passing an option => '', the parser will set its value to "''". When $self->string() is called, the option will be written as: option;
  ex: nocase => '', will result in an option output of: ...., nocase; ...

=cut

sub opts {
	my ($self,$opt,$v) = @_;
	if (defined($opt)) {
		if(ref($opt) eq 'HASH'){
			foreach my $x (keys %$opt){
				$opt->{$x} = fixQuotes($x,$opt->{$x});
				my $pri = (keys %{$self->{_opts}}) + 1;
				$self->{_opts}->{$pri}->{opt} = $x;
				$self->{_opts}->{$pri}->{val} = $opt->{$x};
			}
		}
		else {
			$v = fixQuotes($opt,$v);
			my $pri = (keys %{$self->{_opts}}) + 1;
			$self->{_opts}->{$pri}->{opt} = $opt;
			$self->{_opts}->{$pri}->{val} = $v;
		}
	}
	return $self->{_opts};
}

=head2 opt

Gets the value of the first option with a given name.

  $rule->opt(option);
  print $rule->opt('sid') . ': ' . $rule->opt('msg');

=cut
sub opt {
	my ($self,$opt) = @_;
	if (defined($opt)) {
        	my @sort = sort { $a <=> $b } keys %{$self->opts()};
        	foreach my $key (@sort) {
                		return $self->opts->{$key}->{val} if($self->opts->{$key}->{opt} eq $opt);
        	}
	}
	return undef;
}

# INTERNAL FUNCTIONS ( for now )

sub fixQuotes {
	my ($opt, $v) = @_;
	foreach my $option (@QUOTED_OPTIONS) {
		if (defined($v) && (uc($opt) eq $option)) {
			if (!($v =~ /^\"\S+|\s+\"$/)) {		# do we have the appropriate quotes? (anchored for pcre)
				$v =~ s/^\"|\"$//g;		# strip the quotes
				$v = "\"$v\"";			# fix em
			}
			last;
		}
		elsif(!defined($v)) { $v = "\"\""; }
	}
	return $v;
}

sub parseRule {
	my ($self, $rule) = @_;
	my @r = split(/\(/,$rule,2);
	$r[1] =~ s/\)$//;

	my @meta = split(/\s+/,$r[0]);
	my @opts = split(/\s*;\s*/,$r[1]);

	$self->action(	$meta[0]);
	$self->proto(	$meta[1]);
	$self->src(	$meta[2]);
	$self->sport(	$meta[3]);
	$self->dir(	$meta[4]);
	$self->dst(	$meta[5]);
	$self->dport(	$meta[6]);

	foreach my $x (@opts) {
 		my ($opt, $v) = split(/\s*:\s*/, $x, 2);
		$self->opts($opt, $v);
	}
}

1;
__END__
=head1 AUTHOR

Wes Young, E<lt>saxguard9-cpan@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Wes Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
