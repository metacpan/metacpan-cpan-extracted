package PMLTQ::Command::webtreebank;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Command::webtreebank::VERSION = '1.5.0';
# ABSTRACT: GET actions on treebanks on the web

use PMLTQ::Base 'PMLTQ::Command';
use JSON;
use YAML::Tiny;
use Hash::Merge 'merge';

has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;
  my $subcommand = shift;
  my $config = $self->config;
  unless($subcommand){
    say "Subcommand must be set.";
    return 0;
  }
  my $ua = $self->ua;
  $self->login($ua);
  my $json = JSON->new;

  if($subcommand eq 'list'){
    my $treebanks = $self->get_all_treebanks($ua);
    my $unknown = 0;
    print join("\n",
             map {
              my $tb = $_; 
              join("\t",
                map {
                  $unknown = 1 unless $tb->{$_};
                  my $ret = $tb->{$_} // "<UNKNOWN FIELD $_>";
                  ref($ret) ? $json->encode($ret) : $ret;
                  } split(/[,; |]/,$config->{info}->{fields}) )} @$treebanks
            ),"\n";
    print STDERR "Possible fields: ", join( " ", keys %{$treebanks->[0]}) if $unknown;
  } elsif($subcommand eq 'single') {
    my $treebank = $self->get_treebank($ua);
    print YAML::Tiny->new(merge(
                                merge( $config, $self->user2admin_format($treebank)),
                                {test_query => {
                                  result_dir => 'query_results/'.$treebank->{name},
                                  queries => $self->get_test_queries($treebank)
                                  }}
                                )
                         )->write_string;
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PMLTQ::Command::webtreebank - GET actions on treebanks on the web

=head1 VERSION

version 1.5.0

=head1 SYNOPSIS

  pmltq webtreebank <subcommand>

=head1 DESCRIPTION

=head1 OPTIONS

=head2 subcommands

=over 5

=item list

=over 5

Command with this option returns a list of treebank names (ids).

There in specific option --info-fields with default value "name" that determines which fields should be printed. For example --info-fields="name,title" returns one treebank perl line with tab separated fields name and title.

=back

=item single --treebank_id="<tbid>"

=over 5

Command returns yaml formated string for treebank with name or id <tbid>. This config options are merged with default and current configs. So it can be used for generating configuration files from treebank's options saved on web.

=back

=back

=head1 PARAMS

=over 5

=item B<api_url>

Url to pmltq service

=back

=head1 EXAMPLES

=over 5

=item Creates and executes simple queries on all treebanks on web

for tb in `./script/pmltq webtreebank list`; do  echo "$tb"; ./script/pmltq webtreebank single --treebank_id=$tb | ./script/pmltq webverify -c --; sleep 60; done

=back

=head1 AUTHORS

=over 4

=item *

Petr Pajas <pajas@ufal.mff.cuni.cz>

=item *

Jan Štěpánek <stepanek@ufal.mff.cuni.cz>

=item *

Michal Sedlák <sedlak@ufal.mff.cuni.cz>

=item *

Matyáš Kopp <matyas.kopp@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Institute of Formal and Applied Linguistics (http://ufal.mff.cuni.cz).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
