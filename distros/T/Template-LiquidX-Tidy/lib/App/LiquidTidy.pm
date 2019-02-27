package App::LiquidTidy;

use strict;
use warnings;
use experimental 'signatures';

our $VERSION = '0.01';

use Template::LiquidX::Tidy;
use Template::Liquid;
use Template::LiquidX::Tidy::Tag::include;
use Template::LiquidX::Tidy::Tag::post_url;

sub new ($class, $args) {
    bless $args => $class
}

sub run ($self) {
    die "No file name specified\n" unless $self->{file};
    my $fh;
    if ($self->{file} eq '-') {
	$fh = *STDIN;
    }
    else {
	open $fh, '<', $self->{file} or die "Error opening $self->{file}: $!\n";
    }
    my $content = do { local $/; <$fh>; };

    my $sol = Template::Liquid->parse($content);

    my $liquid_tidy;
    my %opts = (
	force_nl => 1,
       );
    if ($self->{file} =~ /\.markdown/ || $self->{file} =~ /\.md/ || $self->{file} =~ /\.txt/) {
	$opts{html} = 0;
    }

    %opts = (%opts, %$self);
    $liquid_tidy = $sol->{document}->tidy(\%opts);
    print $liquid_tidy;
}

# print Dumper $sol->{document};
# print $sol->{document}->dump();
# print $sol->{document}->tidy({force_nl => 1});
# my $liquid_tidy = $sol->{document}->tidy();

# sub test_html_tidy ($source) {
#     my ($trans, $map) = Template::Liquid->parse($sol)->{document}->transform();
#     print $trans;
#     my @cmd = (qw(tidy
# 	      --indent auto
# 	      --indent-spaces 4
# 	      --show-body-only auto
# 	      --fix-uri no
# 	      --literal-attributes yes
# 	      --preserve-entities yes
# 	      --new-pre-tags body
# 	      --quiet
# 	    ));
#     my ($out, $err);
#     IPC::Run::run \@cmd, \$trans, \$out, \$err;  warn "tidy: $?";

#     print transform_back($out, $map);
# }

# sub dump_map ($map) {
#     for (sort { $a <=> $b } grep !/^__/, keys $map->%*) {
# 	my $i = $map->{$_};
# 	print $_, "\t", (defined $i->{markup} ? $i->{markup} =~ s/\n\K/\t/gr : ''), "\n";
# 	print "\t", $i->{markup_2} =~ s/\n\K/\t/gr, "\n"
# 	    if defined $i->{markup_2};
# 	print "\n";
#     }
# }

1;

=head1 NAME

App::LiquidTidy - Implementation for liquid_tidy script

=head1 SYNOPSIS

    use App::LiquidTidy;
    my $app = App::LiquidTidy->new(%options);
    $app->run;

=head1 DESCRIPTION

See L<liquid_tidy> for the command line tool documentation.

=head1 METHODS

=head2 new(%options)

Create a new app.

It will parse the file specified by C<$options{file}>

Other C<%options> are passed to Template::LiquidX::Tidy

=head2 run

Print the formatted file to standard output.

=cut

