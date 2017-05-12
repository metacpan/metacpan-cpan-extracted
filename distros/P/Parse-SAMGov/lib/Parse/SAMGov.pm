package Parse::SAMGov;
$Parse::SAMGov::VERSION = '0.106';
use strict;
use warnings;
use 5.010;
use Carp;
use IO::All;
use Text::CSV_XS;
use Parse::SAMGov::Entity;
use Parse::SAMGov::Exclusion;
use Parse::SAMGov::Mo;

# ABSTRACT: Parses SAM Entity Management Public Extract Layout from SAM.gov


sub parse_file {
    my ($self, $filename, $cb, $cb_arg) = @_;
    croak "Unable to open file $filename: $!" unless -e $filename;
    my $io = io $filename;
    croak "Unable to create IO::All object for reading $filename"
      unless defined $io;
    my $result      = [];
    my $is_entity   = 0;
    my $entity_info = {};
    while (my $line = $io->getline) {
        chomp $line;
        $line =~ s/^\s+//g;
        $line =~ s/\s+$//g;
        next unless length $line;
        my $obj = Parse::SAMGov::Entity->new;
        if ($line =~ /BOF PUBLIC\s+(\d{8})\s+(\d{8})\s+(\d+)\s+(\d+)/) {
            $is_entity            = 1;
            $entity_info->{date}  = $1;
            $entity_info->{rows}  = $3;
            $entity_info->{seqno} = $4;
            next;
        } elsif ($line =~ /EOF\s+PUBLIC\s+(\d{8})\s+(\d{8})\s+(\d+)\s+(\d+)/) {
            croak "Invalid footer q{$line} in file"
              if (   $entity_info->{date} ne $1
                  or $entity_info->{rows}  ne $3
                  or $entity_info->{seqno} ne $4);
            last;
        } else {
            last unless $is_entity;    # skip this loop and do something else
            my @data = split /\|/x, $line;
            carp "Invalid data line \n$line\n" unless $obj->load(@data);
        }
        if (defined $cb and ref $cb eq 'CODE') {
            my $res = &$cb($obj, $cb_arg);
            push @$result, $obj if $res;
        } else {
            push @$result, $obj;
        }
    }
    unless ($is_entity) {
        my $csv = Text::CSV_XS->new({ binary => 1 })
          or croak "Failed to create Text::CSV_XS object: "
          . Text::CSV_XS->error_diag();
        my $obj = Parse::SAMGov::Exclusion->new;
        while (my $row = $csv->getline($io->io_handle)) {
            carp "Invalid data line \n$row\n" unless $obj->load(@$row);
            if (defined $cb and ref $cb eq 'CODE') {
                my $res = &$cb($obj, $cb_arg);
                push @$result, $obj if $res;
            } else {
                push @$result, $obj;
            }
        }
        $csv->eof or $csv->error_diag();
    }
    return $result if scalar @$result;
    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Parse::SAMGov - Parses SAM Entity Management Public Extract Layout from SAM.gov

=head1 VERSION

version 0.106

=head1 SYNOPSIS

    my $parser = Parse::SAMGov->new;
    my $entities = $parser->parse_file('SAM_PUBLIC_DAILY_20160701.dat');
    foreach my $e (@$entities) {
        ## do something with each entity
        say $e->DUNS, ' is a valid entity';
    }
    #... use in filter mode like grep ...
    my $entities_541511 = $parser->parse_file('SAM_PUBLIC_DAILY_20160701.dat',
                                    sub {
                                        # filter all companies with NAICS code
                                        # being 541511
                                        return $_[0] if exists $_[0]->NAICS->{541511};
                                        return undef;
                                    });

    # ... do something ...
    my $exclusions = $parser->parse_file(exclusion => 'SAM_Exclusions_Public_Extract_16202.CSV');
    foreach my $e (@$exclusions) {
        ## do something with each entity that has been excluded
        say $e->DUNS, ' has been excluded';
    }

=head1 METHODS

=head2 parse_file

This method takes as arguments the file to be parsed and returns an array
reference of L<Parse::SAMGov::Entity> or L<Parse::SAMGOv::Exclusion> objects
depending on the data being parsed. 

If the second argument is a coderef then passes each Entity or
Exclusion object into the callback where the user can select which objects they
want to return. The user has to return 1 if they want the object returned in the
array ref or undef if they do not.

    my $entities = $parser->parse_file('SAM_PUBLIC_DAILY_20160701.dat');
    my $exclusions = $parser->parse_file('SAM_Exclusions_Public_Extract_16202.CSV');
    my $entities = $parser->parse_file('SAM_PUBLIC_DAILY_20160701.dat', sub {
        my ($entity_or_exclusion, $optional_user_arg) = @_;
        #... do something ...
        return 1 if (!$entity_or_exclusion->is_private);
        return undef;
    }, $optional_user_arg);

=head1 SEE ALSO

L<Parse::SAMGov::Entity> and L<Parse::SAMGov::Exclusion> for the object
definitions.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Selective Intellect LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
