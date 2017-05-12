package Module::Install::Bundle::Platypus;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.00002';

use base qw(Module::Install::Base);

sub bundle_platypus {
    my ($self, %args) = @_;


    my $class = delete $args{class} || 'App::BundleDeps::Platypus';
    foreach my $required qw(script) {
        die "required parameter $required not specified in bundle_platypus"
            unless $args{$required};
    }
    $args{version} ||= $self->version() ||
        die "could not guess version for bundle_platypus";

    $args{extlib} ||= 'extlib';

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Varname = "MIBP_VAR";
    local $Data::Dumper::Useqq = 1;
    my $args = Dumper(\%args);
    $args =~ s/^\s*\$MIBP_VAR\d+\s*=\s*{//;
    $args =~ s/}\s*;?\s*$//;

    $self->Makefile->postamble(<<EOM);
platypus: metafile
\t\$(FULLPERLRUN) -M$class -e '$class->new($args)->bundle_from_meta()'
EOM
}

1;

__END__

=head1 NAME

Module::Install::Bundle::Platypus - Bundle Your Mac App With Platypus

=head1 SYNOPSIS

    # in your Makefile.PL
    use inc::Module::Install;

    bundle_platypus
        extlib => 'extlib', # default,
        script => 'myapp.pl',
        app => $appname,
        author => $author,
        icon => $icon,
        identifier => $identifier,
        resources => \@resources,
        background => $boolean,
        version => $version, # uses dist version by default
    WriteAll;

    > make platypus

=head1 SEE ALSO

Module::Install::Bundle::LocalLib

=head1 AUTHOR

Daisuke Maki - C<< <daisuke@endeworks.jp> >>

Miyagawa Tatsuhiko - The juicy bits about using platypus

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut