package Mojolicious::Command::secret;

use Mojo::Base 'Mojolicious::Command';
use Mojo::Util 'class_to_path';

use File::Spec;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case no_auto_abbrev);   # Match Mojo's commands

our $VERSION = '0.03';

has description => "Create application secrets() consisting of random bytes\n";
has usage => <<USAGE;
usage $0 secret [OPTIONS]

OPTIONS:
  -c, --count     N              Generate N secrets. Defaults to 1.
  -f, --force                    Overwrite an existing secret. Defaults to 0.
  -g, --generator MODULE=method  Module & method to generate the secret. The method must
				 accept an integer argument. Defaults to Crypt::URandom=urandom
    				 and Crypt::OpenSSL::Random=random_bytes
  -p, --print                    Just print the secret, do not add it to your application.
  -s, --size      SIZE           Number of bytes to use. Defaults to 32.

Default options can be added to the MOJO_SECRET_OPTIONS environment variable.
USAGE

sub run
{
    my ($self, @argv) = @_;
    unshift @argv, split /\s+/, $ENV{MOJO_SECRET_OPTIONS} if $ENV{MOJO_SECRET_OPTIONS};

    my ($count, $force, $size, $module, $print);
    my $ok = GetOptionsFromArray(\@argv,
                                 'c|count=i'     => \$count,
                                 'f|force'       => \$force,
                                 's|size=i'      => \$size,
                                 'p|print'       => \$print,
                                 'g|generator=s' => \$module);
    return unless $ok;

    my $secrets  = _create_secrets($module, $size, $count);
    my $filename = class_to_path(ref($self->app));
    my $path     = $filename eq 'Mojolicious/Lite.pm' ? $0 : File::Spec->catdir('lib', $filename);

    # If we're called as `mojo` just print the secrets
    my $base = join '/', (File::Spec->splitdir($path))[-2,-1];   # Warning if perl ./app.pl secret
    if($print || $base eq 'bin/mojo') {
        print "$_\n" for @$secrets;
        return;
    }

    _insert_secrets($secrets, $path, $force);
    print "Secret created!\n";
}

sub _insert_secrets
{
    my ($secrets, $path, $force) = @_;

    my $args = join ', ', map "'$_'", @$secrets;
    my $code = sprintf q|->secrets([%s]);|, $args;

    open my $in, '<:encoding(utf8)', $path or die "Error opening $path: $!\n";
    my $data = do { local $/; <$in> };

    my $created = 0;
    if($data =~ m|\w->secrets\(\s*\[(.*)\]\s*\)|) { # '
        if(!$force) {
            die "Your application already includes secrets (use -f to overwrite it)\n";
        }

        my ($i, $j) = ($-[1], $+[1] - $-[1]);
        substr($data, $i, $j) = $args;
        $created = 1;
    }
    # Preserve indentation and prepend method target to $code.
    # First try to match a full app, then a lite one
    elsif($data =~ s/(sub\s+startup\s*\{(\s*).+(\$self).+)$/$1$2$3$code/m ||
          $data =~ s/^((\s*)\b(app)->\w+)/$2$3$code$1/m) {
        $created = 1;
    }

    if(!$created) {
        die "Can't figure out where to insert the call to secrets()\n";
    }

    my $out;
    open $out, '>:encoding(utf8)', $path
	and print $out $data
	and close $out
	or die "Error writing secrets to $path: $!\n";
}

sub _create_secrets
{
    my $module = shift;
    my $size   = shift || 32;
    die "The size of the secret must be > 0, got '$size'\n" unless $size > 0;

    my $count  = shift || 1;
    die "The number of secrets must be > 0, got '$count'\n" unless $count > 0;

    my @lookup = $module ? $module : qw|Crypt::URandom=urandom Crypt::OpenSSL::Random=random_bytes|;

    my ($class, $method);
    while(defined(my $mod = shift @lookup)) {
	($class, $method) = split /=/, $mod, 2;
	eval "require $class; 1"
	    and last
	    or @lookup
	    or die "Module '$class' not found\n";
    }

    my $secrets = [];
    {
        no strict 'refs';
	no warnings;

        if(!exists ${"${class}::"}{$method}) {
            die "$class has no method named '$method'\n";
        }

        eval {
	    for(1..$count) {
		push @$secrets, unpack "H*", "${class}::$method"->($size)
	    }
	};
        die "Can't create secret: $@\n" if $@;
    }

    $secrets;
}

1;

=pod

=head1 NAME

Mojolicious::Command::secret - Create application secrets() consisting of random bytes

=head1 MOJOLICIOUS VERSION

If your Mojolicious version is less than 4.63 then you must
L<use version 0.02|https://metacpan.org/release/SHAW/Mojolicious-Command-secret-0.02>
of this module.

=head1 DESCRIPTION

Tired of manually creating and adding secrets? Me too! Use this command to create secrets
and automatically add them to your C<Mojolicous> or C<Mojolicious::Lite> application:

 ./script/your_app secret
 ./lite_app secret

B<This will modify the appropriate application file>, though existing secrets will not be overridden
unless the C<-f> option is used.

It is assumed that your file contains UTF-8 data and that you use C<$self> or C<app> to refer
to your application instance.

If you do not want to automatically add secrets to your application use the C<mojo secret> command or
the C<-p> option and the secrets will be printed to C<STDOUT> instead:

 mojo secret
 ./script/your_app secret -p

=head1 OPTIONS

 -c, --count     N              Generate N secrets. Defaults to 1.
 -f, --force                    Overwrite an existing secret. Defaults to 0.
 -g, --generator MODULE=method  Module & method to generate the secret. The method must
                                accept an integer argument. Defaults to Crypt::URandom=urandom.
                                and Crypt::OpenSSL::Random=random_bytes
 -p, --print                    Print the secret, do not add it to your application.
 -s, --size      SIZE           Number of bytes to use. Defaults to 32.

Default options can be added to the C<MOJO_SECRET_OPTIONS> environment variable.

=head1 SEE ALSO

L<Crypt::URandom>, L<Crypt::OpenSSL::Random>

=head1 AUTHOR

(c) 2012 Skye Shaw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
