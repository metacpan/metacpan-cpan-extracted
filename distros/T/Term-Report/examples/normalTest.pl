#!/usr/bin/perl

   $|++;
   use Term::Report;
   use Time::HiRes qw(usleep);

   my $items = 200;
   my $report = Term::Report->new(
            startRow => 5,
            numFormat => 1, 
            statusBar => [
               label => 'Widget Analysis: ',
               subTextAlign => 'center',
               showTime=>1,
            ],
   );

   my $status = $report->{statusBar};
   $status->setItems($items);
   $status->start;

   $report->savePoint('total', "Total widgets: ", 1);
   $report->savePoint('discarded', "\n  Widgets discarded: ", 1);

   for (1..$items){
      $report->finePrint('total', 0, $_);

      if (!($_%int((rand(10)+rand(10)+1)))){
         $report->finePrint('discarded', 0, ++$discard);
         $status->subText("Discarding bad widgets all over the place so we can make this text longer and longer and longer");
      }
      else{
         $status->subText("Locating widgets");
      }

      usleep(35000);
      $status->update;
   }

   $status->reset({reverse=>1, subText=>'Processing widgets', setItems=>($items-$discard), start=>1});
   $report->savePoint('inventory', "\n\nInventorying widgets: ", 1);

   for (1..($items-$discard)){
      $report->finePrint('inventory', 0, $_);
      $status->update;
   }

   $report->printBarReport(
      "\n\n\n\n    Summary for widgets: \n\n",
      {
            "       Total:        " => $items,
            "       Good Widgets: " => $items-$discard,
            "       Bad Widgets:  " => $discard,
      }
   );

	$report->finished;

