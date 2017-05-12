# $Id: Term.pm,v 1.4 2001/05/24 07:21:28 btrott Exp $

package Net::SSH::Perl::Util::Term;
use strict;
use warnings;

sub _prompt {
    my($prompt, $def, $echo) = @_;
    unless ($echo) {
        return _read_passphrase($prompt);
    }
    else {
        print $prompt . ($def ? "[$def] " : "");
        chomp(my $ans = <STDIN>);
        return $ans ? $ans : $def;
    }
}

sub _read_passphrase {
    my($prompt) = @_;
    print $prompt;
    require Term::ReadKey;
    Term::ReadKey->import;
    ReadMode('noecho');
    chomp(my $pwd = ReadLine(0));
    ReadMode('restore');
    print "\n";
    $pwd;
}

sub _read_yes_or_no {
    my($prompt, $def) = @_;
    print $prompt, " [$def] ";
    chomp(my $ans = <STDIN>);
    $ans = $def unless $ans;
    $ans =~ /^y/i;
}

1;
