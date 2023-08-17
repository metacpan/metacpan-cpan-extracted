
sub execute_slurm {
    my ($name, $command, $threads, $memory) = shift;

    $command =~ s/\"/\\\"/g;
    my $slurm_cmd = qq(sbatch --job-name=$name --nodes=1 --ntasks-per-node=$threads --mem=${memory}GB --wrap="$command");
    my $output = `$slurm_cmd`;
    
    if ($? == -1) {
        print STDERR "ERROR executing $command:\nFailed to execute command: $!";
        return undef;
    } elsif ($? & 127) {
        print STDERR "ERROR executing $command:\nCommand died with signal " . ($? & 127);
    } else {
        my $exit_code = $? >> 8;
        print "Command exited with code $exit_code\n";
        print "Output:\n$output\n";
        return undef;
    }
    # Return JOBID if successful
    if ($output =~ /Submitted batch job (\d+)/i) {
        return $1;
    } else {
        return undef;
    }
}

for my $file (@list_of_files) {
    my $command = qq(annotate -i $file -o $outdir -t $threads);
    my $job_id = execute_slurm('annotate', $command, $threads, $memory_gb);
}