use Config;

symlink "os/Linux.c", "OS.c" || die "Could not link os/Linux.c to os/OS.c\n";

# We might have a non-threading perl, which doesn't add this
# necessary link option.
my $thread_lib = "-lpthread";

if( $Config{libs} !~ /(?:^|\s)$thread_lib(?:\s|$)/ ) {
  $self->{LIBS} ||= [];
  push @{ $self->{LIBS} }, $thread_lib;
}
