package Support;
use strict;
use IO::File;
use File::Spec;
use Test::More;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(all_modules test_trace);

sub test_trace {
    my ($type, $file, $info) = @_;
    
    my $num_threads = $info->{'threads'};
    my $num_lines   = $info->{'trace_lines'};
    my $get_thread  = $info->{'thread'};
    my $num_frames  = $info->{'frames'};
    my $stack       = $info->{'stack'};
    my $crash_frame_num = $info->{'crash_frame'};
    my $description = $info->{'description'};
    
    my $trace_file = new IO::File("t/traces/" . lc($type) . "/$file");
    my $trace_text;
    { local $/ = undef; $trace_text = <$trace_file>; }
    $trace_file->close();
    
    my $trace;
    my $class = "Parse::StackTrace::Type::$type";
    use_ok($class);
    
    my $debug;
    if (my $ps_debug = $ENV{'PS_DEBUG'}) {
        if ($ps_debug == 1 or $ps_debug eq $file) {
            $debug = 1;
        }
    }
    
    isa_ok($trace = $class->parse(text => $trace_text, debug => $debug),
           $class, $file);
    
    is(scalar @{ $trace->threads }, $num_threads,
       "trace has $num_threads threads");
    
    is(scalar @{ $trace->text_lines }, $num_lines, "trace has $num_lines lines")
        or diag("First Line: [" . $trace->text_lines->[0] . ']'
                . "Last Line: [" . $trace->text_lines->[-1] . ']');
    
    my $thread;
    my $thread_array_pos = defined $info->{thread_array_pos}
                           ? $info->{thread_array_pos}
                           : $num_threads - $get_thread;
    is($thread = $trace->thread_number($get_thread),
       $trace->threads->[$thread_array_pos],
       "thread_number($get_thread) returns the right thread")
        or diag("Threads: " . join(', ', map($_->number, @{ $trace->threads })));
    
    ok(!$trace->thread_number($num_threads + 1),
       'there is no thread number ' . ($num_threads + 1));
    
    is(scalar @{ $thread->frames }, $num_frames,
       "thread has $num_frames frames")
        or diag("Frames: " . join(', ', map { $_->number } @{ $thread->frames }));
        
    if (defined $stack) {
        my @got_stack = map { $_->function } @{ $thread->frames };
        is_deeply(\@got_stack, $stack, 'thread has the right function stack');
    }
    
    if (defined $description) {
        is($thread->description, $description,
           "thread description is: $description");
    }
    
    is($thread->frame_number(0), $thread->frames->[0],
       'frame_number(0) returns first frame');
    
    ok(!$thread->frame_number($num_frames),
       "there is no frame number $num_frames");

    if (defined $crash_frame_num) {
        is($thread, $trace->thread_with_crash,
           'this thread is the thread_with_crash');

        my $crash_frame;
        ok($crash_frame = $thread->frame_with_crash, 'thread has crash frame');
        is($crash_frame->number, $crash_frame_num,
           "crash frame is frame number $crash_frame_num");
        
        # For Python
        if (my $error_loc = $info->{error_location}) {
            is($crash_frame->error_location, $error_loc,
               "crash frame has the right error_location");
        }
    }
}

# Stolen from Test::Pod::Coverage
sub all_modules {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map {$_,1} @starters;

    my @queue = @starters;

    my @modules;
    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" && $_ ne '.bzr' }
                             @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next unless $file =~ /\.pm$/;

            my @parts = File::Spec->splitdir( $file );
            shift @parts if @parts && exists $starters{$parts[0]};
            shift @parts if @parts && $parts[0] eq "lib";
            $parts[-1] =~ s/\.pm$// if @parts;

            # Untaint the parts
            for ( @parts ) {
                if ( /^([a-zA-Z0-9_\.\-]+)$/ && ($_ eq $1) ) {
                    $_ = $1;  # Untaint the original
                }
                else {
                    die qq{Invalid and untaintable filename "$file"!};
                }
            }
            my $module = join( "::", @parts );
            push( @modules, $module );
        }
    } # while

    return @modules;
}
