package String::Normal::Config::AreaCodes;
use strict;
use warnings;

use String::Normal::Config;


sub _data {
    my %params = @_;

    my $fh;
    if ($params{area_codes}) {
        open $fh, $params{area_codes} or die "Can't read '$params{area_codes}' $!\n";
    } else {
        $fh = *DATA;
    }

    chomp( my @codes = <$fh> );
    return \@codes;
}

1;

=head1 NAME

String::Normal::Config::AreaCodes;

=head1 DESCRIPTION

This package defines valid U.S. area codes.

=head1 STRUCTURE

One entry per line. Each entry should be exactly 3 digits with no other characters.
See C<__DATA__> section for examples.

You can provide your own data by creating a text file containing your
values and provide the path to that file via the constructor: 

  my $normalizer = String::Normal->new( area_codes => '/path/to/values.txt' );

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

__DATA__
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
224
225
226
228
229
231
234
236
239
240
242
246
248
250
251
252
253
254
256
260
262
264
267
268
269
270
276
278
281
283
284
289
301
302
303
304
305
306
307
308
309
310
311
312
313
314
315
316
317
318
319
320
321
323
325
330
331
334
336
337
339
340
341
345
347
351
352
360
361
369
380
385
386
401
402
403
404
405
406
407
408
409
410
411
412
413
414
415
416
417
418
419
423
424
425
430
432
434
435
438
440
441
442
443
450
456
464
469
470
473
475
478
479
480
484
500
501
502
503
504
505
506
507
508
509
510
511
512
513
514
515
516
517
518
519
520
530
540
541
551
555
557
559
561
562
563
564
567
570
571
573
574
575
580
585
586
600
601
602
603
604
605
606
607
608
609
610
611
612
613
614
615
616
617
618
619
620
623
626
627
628
630
631
636
641
646
647
649
650
651
660
661
662
664
669
670
671
678
679
682
684
689
700
701
702
703
704
705
706
707
708
709
710
711
712
713
714
715
716
717
718
719
720
724
727
731
732
734
737
740
747
754
757
758
760
762
763
764
765
767
769
770
772
773
774
775
778
779
780
781
784
785
786
787
800
801
802
803
804
805
806
807
808
809
810
811
812
813
814
815
816
817
818
819
822
828
829
830
831
832
833
835
843
844
845
847
848
850
855
856
857
858
859
860
862
863
864
865
866
867
868
869
870
872
876
877
878
880
881
882
888
898
900
901
902
903
904
905
906
907
908
909
910
911
912
913
914
915
916
917
918
919
920
925
927
928
931
935
936
937
939
940
941
947
949
951
952
954
956
957
959
970
971
972
973
975
976
978
979
980
984
985
989
999
