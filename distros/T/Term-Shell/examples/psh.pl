#!/usr/bin/perl -w

use strict;

my $obj = PSH->new;
$obj->cmdloop;

package PSH;
use base qw(Term::Shell);
use Data::Dumper;
use Cwd;

sub precmd {
    my $o = shift;
    my $hnd = shift;
    my $cmd = shift;
    my $args = shift;
    @$args = expand(@$args);
}
sub expand {
    for (@_) {
	$_ =~ s[^~][$ENV{HOME}];
	$_ =~ s[\$([_A-Za-z0-9]+)][$ENV{$1} || '']eg;
    }
    @_;
}

sub prompt_str {
    my $cwd = cwd;
    $cwd =~ s[^\Q$ENV{HOME}\E][~];
    "psh:$cwd> "
}

sub smry_eval { "how to evaluate Perl code" }
sub help_eval {
    <<'END';
You can evaluate snippets of Perl code just by putting them on a line
beginning with !:

    psh:~> ! print "$_\n" for keys %ENV

END
}

#=============================================================================
# External commands
#=============================================================================
{
    my $eval_num = "000001";
    sub catch_run {
	my ($o, $command, @args) = @_;

	# Evaluate perl code if it's a ! line.
	if ($command =~ s/^!//) {
	    (my $code = $o->line) =~ s/^!//;
	    my $really_long_string = <<END;
package PSH::namespace_$eval_num;
{
    no strict;
    eval "no warnings";
    local \$^W = 0;
    $code;
}
END
	    {
		local *_;
		my ($eval_num, $o, $command, @args, $code);
		eval $really_long_string;
	    }
	    print "$@\n" if $@;
	    $eval_num++;
	}

	# Real external commands.
	else {
	    system($command, @args);
	}
    }
}

sub catch_comp {
    my ($o, $action, $word, $line, $start) = @_;

    # Complete environment variables (not working)
    if ($word =~ /^\$/) {
	return $o->completions($word, [keys %ENV]);
    }
    my @files = glob("$word*");
    return $o->completions($word, \@files);
}

sub comp_ {
    my ($o, $word, $line, $start) = @_;
    my @exes;
    use Config;
    for my $part (split /\Q$Config{path_sep}\E/, $ENV{PATH}) {
	next unless -d $part;
	opendir (PART, $part) or die "can't opendir $part: $!";
	while (my $entry = readdir(PART)) {
	    my $file = "$part/$entry";
	    push @exes, $entry if -f $file and -x $file;
	}
	closedir (PART) or die "can't closedir $part: $!";
    }
    my @comp = grep { length($_) } $o->possible_actions($word, 'run', 1);
    push @comp, $o->completions($word, \@exes);
    @comp = sort @comp;
    @comp;
}

#=============================================================================
# Shell Builtins
#=============================================================================
sub smry_echo { 'output the args' }
sub help_echo {
    <<'END';
echo: echo [arg ...]
    Output the args.
END
}
sub run_echo {
    my ($o, @args) = @_;
    my @exp = expand(@args);
    defined $_ or $_ = '' for @exp;
    print "@exp\n" if @exp;
}

sub smry_set { 'set environment variables' }
sub help_set {
    <<'END';
set: set [ name[=value] ... ]
    set lets you manipulate environment variables. You can view environment
    variables using 'set'. To view specific variables, use 'set name'. To set
    environment variables, use 'set foo=bar'.
END
}
sub run_set {
    my ($o, @args) = @_;
    if (@args) {
	for my $arg (@args) {
	    my ($key, $val) = split /=/, $arg;
	    if (defined $val) {
		$ENV{$key} = $val;
	    }
	    else {
		$val = $ENV{$key} || '';
		print "$key=$val\n";
	    }
	}
    }
    else {
	my ($key, $val);
	while(($key, $val) = each %ENV) {
	    print "$key=$val\n";
	}
    }
}

sub smry_cd { 'change working directory' }
sub help_cd {
    <<'END';
cd: cd [dir]
    Change the current directory to DIR.  The variable $HOME is the default
    DIR.
END
}
sub run_cd {
    my ($o, $dir) = @_;
    $dir = $ENV{HOME} unless defined $dir;
    chdir $dir or do {
	print "$0: $dir: $!\n";
	return;
    };
    $ENV{PWD} = $dir;
}

__END__

# Not working yet...

sub smry_alias { 'view or set command aliases' }
sub help_alias {
    <<'END';
alias: [ name[=value] ... ]
    'alias' with no arguments prints the list of aliases in the form
    NAME=VALUE on standard output. An alias is defined for each NAME whose
    VALUE is given.
END
}
sub run_alias {
    my $o = shift;
    if (@_) {
	for my $a (@_) {
	    my ($key, $val) = split /=/, $a;
	    if (defined $val) {
		$o->{SHELL}{alias}{$key} = $val;
	    }
	    else {
		$val = $o->{SHELL}{alias}{$key};
		print "alias $key=$val\n" if defined $val;
		print "alias: `$key' not found\n" if not defined $val;
	    }
	}
    }
    else {
	my ($key, $val);
	while (($key, $val) = each %{$o->{SHELL}{alias}}) {
	    print "alias $key=$val\n";
	}
    }
}
