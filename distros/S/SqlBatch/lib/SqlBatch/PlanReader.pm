package SqlBatch::PlanReader;

# ABSTRACT: Class reading an instruction plan

use v5.16;
use strict;
use warnings;
use utf8;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;
use Text::CSV_XS;
use SqlBatch::AbstractPlan;
use SqlBatch::BeginInstruction;
use SqlBatch::CommitInstruction;
use SqlBatch::RollbackInstruction;
use SqlBatch::SqlInstruction;
use SqlBatch::InsertInstruction;
use SqlBatch::DeleteInstruction;


sub new {
    my ($class, $directory, $plan, $config)=@_;

    my $self = {
	config      => $config,
	plan        => $plan,
 	directory   => $directory,	
    };

    return bless $self, $class;
}

sub load {
    my $self = shift;

    say "Loading plan";
    my $plan       = $self->{plan};
    my @file_paths = $self->files;

    my $verbosity = $self->{config}->verbosity;
    for my $current_file (@file_paths) {
	say "Load batchfile: ".$current_file if ($verbosity > 1);

	$self->{current_file} = $current_file;
	$plan->add_instructions($self->load_tasks_file_instructions);
    }
}

sub files {
    my $self = shift;

    my @override = @_;
    if (scalar(@override)) {
	$self->{files} = \@override;
    }
    
    my $config = $self->{config};

    unless (defined $self->{files}) {
	my $from_file     = $config->item('from_file') // "";
	my $to_file       = $config->item('to_file') // "";
	my $exclude_files = $config->item('exclude_files');
	my %exclusions    = map { $_ => 1 } @$exclude_files;
	my $dir           = $config->item('directory');
	
	opendir(my $dh, $dir) || croak "Can't opendir $dir: $!";
	my @all_files          = sort grep { -f "$dir/$_" } readdir($dh);
	my $fileextension      = $config->item('fileextension');
	my @all_sqlbatch_files = grep { /\.$fileextension$/ } @all_files;
	closedir $dh;
	
	
	my $check_for_first = defined $from_file ? 0 : 1;
	my $check_for_last  = defined $to_file   ? 0 : 1;
	my $past_first = $check_for_first ? 0 : 1;
	
	my @files = grep {
	    my $file    = $_;
	    my $addfile;
	    if ($check_for_first) {
		$past_first = 1 if ($file eq $from_file);
		$addfile    = 1;
	    }
	    if ($past_first) {
		unless (defined $exclusions{$file}) {
		    $addfile = 1;
		}
	    }
	    if ($check_for_last) {
		$addfile = 0;
	    }
	    $addfile
	} @all_sqlbatch_files;
	
	my @paths      = map { $dir.'/'.$_ } @files;
	$self->{files} = \@paths;
    }
    return wantarray ? @{$self->{files} } : $self->{files} ;
}

sub load_tasks_file_instructions {
    my $self         = shift;
    my $current_file = shift // $self->{current_file};

    open(FH,"<:encoding(utf8)",$current_file) || croak "File $current_file could not be openned";
    my @alllines = <FH>;
    close FH;

    # Remove comments
    my @lines = grep { ! /^#/ } @alllines;
    $self->{lines_to_parse} = \@lines;
    
    my %tags;
    my @sequence;

    my $line_nr = 1;
    while (scalar(@lines)) {
	my @instructions;
	my $line = shift @lines;
	my %args = (
	    file    => $current_file,
	    line_nr => $line_nr,	
	    );

	if ($line =~ /^--SQL--/) {
	    eval {
		%args = (%args,$self->_parse_section_args("--SQL--",$line));
	    };
	    if ($@) {
		croak "SQL-section arguments failed in file $current_file (line: $line_nr): $@";
	    }
	    @instructions  = $self->_sql_instruction(%args);

	} elsif ($line =~ /^--INSERT--/) {
	    my $table;
	    eval {
		%args = (%args,$self->_parse_section_args(
			     "--INSERT--",
			     $line,
			     "table=s"=>\$table,
			 ));
	    };
	    if ($@) {
		croak "INSERT-section arguments failed in file $current_file (line: $line_nr): $@";
	    }
	    $args{table}   = $table;
	    @instructions  = $self->_insert_csv_instructions(%args);

	} elsif ($line =~ /^--DELETE--/) {
	    my $table;
	    eval {
		%args = (%args,$self->_parse_section_args(
			     "--DELETE--",
			     $line,
			     "table=s"=>\$table,
			 ));
	    };
	    if ($@) {
		croak "DELETE-section arguments failed in file $current_file (line: $line_nr): $@";
	    }
	    $args{table}   = $table;
	    @instructions  = $self->_delete_csv_instructions(%args);

	} elsif ($line =~ /^--BEGIN--/) {
	    @instructions = (
		SqlBatch::BeginInstruction->new(
		    $self->{config},
		    %args
		)
		);

	} elsif ($line =~ /^--COMMIT--/) {
	    @instructions = (
		SqlBatch::CommitInstruction->new(
		    $self->{config},
		    %args
		)
		);

	} elsif ($line =~ /^--ROLLBACK--/) {
	    @instructions = (
		SqlBatch::RollbackInstruction->new(
		    $self->{config},
		    %args
		)
		);
	    
	} elsif ($line =~ /^--PERL--/) {
	    my $class;

	    eval {
		%args = (%args,$self->_parse_section_args(
			     "--PERL--",
			     $line,
			     "class=s"=>\$class,
			 ));
	    };
	    if ($@) {
		croak "PERL-section arguments failed in file $current_file (line: $line_nr): $@";
	    }

	    my $content   = $self->_read_content_section_string(\@lines,%args);
	    eval("require $class;");
	    @instructions = (
		$class->new(
		    $self->{config},
		    $content,
		    %args
		)
		);

	} else {
	    say "Ignored line ($current_file;$line_nr) with content: $line";
	    next;
	}

	push @sequence,@instructions;
	$line_nr++;
    }
    return @sequence;
}

sub _parse_section_args {
    my $self       = shift;
    my $section    = shift;
    my $line       = shift;
    my %extra_args = @_;

    chomp $line;
    $line =~ /$section(.*)/;
    my $rest = $1;
    my @arg_strings = grep { ! $_ eq '' } split /\s/,$rest;

    my $id        = 'Undefined id';
    my $separator = ';';
    my $quote     = '"';
    my $end       = 'END';
    my $tags      = '';

    GetOptionsFromArray(
	\@arg_strings,
	'id:s'        => \$id,
	'separator:s' => \$separator,
	'quote:s'     => \$quote,
	'end:s'       => \$end,
	'tags:s'      => \$tags,
	%extra_args,
	);

    $end         = '--'.$end.'--';
    my @tags     = split /,/,$tags;
    my %pos_tags = map { $_ => 1 } grep { ! /^!/ } @tags;
    my %neg_tags = map { 
	my $tag = $_;
	$tag =~ s/^!//;
	$tag => 1 
    } grep { /^!/ } @tags;

    my %args = (
	id               => $id,
	separator        => $separator,
	quote            => $quote,
	end              => $end,
	run_if_tags      => \%pos_tags,
	run_not_if_tags  => \%neg_tags,
    );

    return %args;
}

sub _sql_instruction {
    my $self  = shift;
    my %args  = @_;

    my $lines = $self->{lines_to_parse};
    my @sqllines;
    while (my $line = shift @$lines) {
#	say $line;
	last if ($line =~/^$args{end}/);

	# Add line to SQL-statement
	push @sqllines,$line;
    }

    return SqlBatch::SqlInstruction->new (
	$self->{config},
	join("\n",@sqllines),
	%args,
    );    

}

sub _insert_csv_instructions {
    my $self  = shift;
    my %args  = @_;

    my $sth_placeholder = undef;
    my $lines           = $self->{lines_to_parse};
    my @instructions    = map {
	SqlBatch::InsertInstruction->new(
	    $self->{config},
	    $_,
	    \$sth_placeholder,
	    %args,
	    );
    } ($self->_parse_csv($lines,%args));

    return @instructions;
}

sub _delete_csv_instructions {
    my $self  = shift;
    my %args  = @_;

    my $sth_placeholder = undef;
    my $lines = $self->{lines_to_parse};

    my @instructions = map {
	SqlBatch::DeleteInstruction->new(
	    $self->{config},
	    $_,
	    \$sth_placeholder,
	    %args,
	    );
    } ($self->_parse_csv($lines,%args));

    return @instructions;
}

sub _read_content_section_string {
    my $self  = shift;
    my $lines = shift;
    my %args  = @_;

    my $end = $args{end};
    my @resultlines;
    while (my $line = shift @$lines) {
	last if ($line =~ /^$end/);

	# Add line to SQL-statement
	push @resultlines,$line;
    }

    return join("",@resultlines);
}

sub _parse_csv {
    my $self  = shift;
    my $lines = shift;
    my %args  = @_;

    my $string = $self->_read_content_section_string($lines,%args);
    open my $fh, "<:encoding(utf8)", \$string;

    # Read/parse CSV    
    my $csv = Text::CSV_XS->new (
	{ 
	    sep         => $args{separator},
	    quote       => $args{quote},
	    binary      => 1, 
	    auto_diag   => 1,
	    decode_utf8 => 1,
	}
	);
    my @cols = @{$csv->getline ($fh)};
    $csv->column_names(@cols);

    my @rows;
    while (my $row = $csv->getline_hr($fh)) {
#	say Dumper($row);
	push @rows, $row;
    }
    
    close $fh;

    return @rows;
} 

1;

__END__

=head1 NAME

SqlBatch::PlanReader

=head1 DESCRIPTION

This class reads the sqlbatch files and loads their content into a L<SqlBatch::Plan>

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
