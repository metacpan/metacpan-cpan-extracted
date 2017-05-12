#!/usr/bin/perl

   $|++;
   use Data::Dumper;
   use Term::Report;
   use Time::HiRes qw(usleep);

   my $file = 'fileTest.pl';
   my $items = -s $file;

   my $report = Term::Report->new(
            startRow  => 5,
            numFormat => 1, 
            statusBar => [
                  label        => 'File Parsing: ',
                  subTextAlign => 'center',
                  showTime     => 1,
            ],
   );

   my $status = $report->{statusBar};
   $status->setItems($items);
   $status->start;

   $report->savePoint('linesRead', "Lines read: ", 0);
   $report->savePoint('bytesRead', "\n  Bytes read: ", 0);

   open FILE, $file;

   my $bytes;
   while (<FILE>){
      $bytes+=length $_;
      $report->finePrint('linesRead', 0, $.);
      $report->finePrint('bytesRead', 0, $bytes);

      usleep(75000);
      $status->update(length $_);
   }

	$report->finished;
