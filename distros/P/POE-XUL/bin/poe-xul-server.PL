#!perl -w

use strict;
use Config;

my $START_PERL  = $Config{startperl};
my $PORT        = $ARGV[1] || 8077;
my $INSTALL_DIR = $ARGV[2] || '/usr/local/xul-node';
my $TARGET      = $ARGV[0] || die "no target given";
my $SCRIPT      = join '', <DATA>;

for ($SCRIPT) {
	s/~~START_PERL~~/$START_PERL/g;
	s/~~PORT~~/$PORT/g;
	s/~~INSTALL_DIR~~/$INSTALL_DIR/g;
}

open F, ">$TARGET" or die "cannot create `$TARGET': $!";
print F $SCRIPT;
close F or die "cannot close `$TARGET': $!";
chmod 0755, $TARGET;

__END__
~~START_PERL~~ -w

use strict;
use Getopt::Long;
use Pod::Usage;
use XUL::Node::Server;

my $PORT = ~~PORT~~;
my $ROOT = '~~INSTALL_DIR~~';
my $HELP = 0;

GetOptions( 
	'port=i' => \$PORT,
	'root=s' => \$ROOT,
	'help'   => \$HELP,
) or pod2usage(2); 

pod2usage(1) if $HELP;

start($PORT, $ROOT);

=head1 NAME

xul-node-server - start POE-XUL HTTP server

=head1 SYNOPSIS

xul-node-server [options]

Options:

  --port   Port (default is ~~PORT~~)
  --root   Document root (default is ~~INSTALL_DIR~~)
  --help   Show this message

=cut


