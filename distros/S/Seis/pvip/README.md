PVIP - Perl6 parser library
===========================

This is a Perl6 parser library written in C.

Runtime deps
------------

Only standard C99 library is required.

Build dependencies
------------------

C99 compiler only, maybe.

Project goal
------------

Build perfect perl6 parser library for writing perl6 interpreter.

Interface stability
-------------------

It's unstable for now. We will change any interfaces without notice.

Known bugs
----------

### `@a[4]:exists`

pvip can't parse this thing corectly.

### grammars

pvip does not support grammer yet.

### END => 3

It should generate pair.

Project status of pvip
----------------------

pvip was tested with roast, the Perl6 testing suite.
Here is the current status of coverage. This project was started at Mid. 2013.
And it supports 30+% of roast.

You can see the current project status by the [HRForecast](http://hf.64p.org/list/perl6/pvip).

<iframe src="http://hf.64p.org/ifr_complex/perl6/pvip/burndown?t=m" width="425" height="355" frameborder="0" marginwidth="0" marginheight="0" scrolling="no"></iframe>

    2013-07-14 09:40 - OK:  44, FAIL: 828 (  5.04%)
    2013-07-14 09:59 - OK:  50, FAIL: 822 (  5.73%)
    2013-07-14 10:45 - OK:  60, FAIL: 812 (  6.88%)
    2013-07-16 08:07 - OK:  73, FAIL: 799 (  8.37%)
    2013-07-16 08:15 - OK:  58, FAIL: 814 (  6.65%)
    2013-07-16 08:36 - OK:  65, FAIL: 807 (  7.45%)
    2013-07-16 09:26 - OK:  88, FAIL: 784 ( 10.09%)
    2013-07-16 11:59 - OK:  89, FAIL: 783 ( 10.21%) in 8.218049 sec
    2013-07-16 12:50 - OK:  92, FAIL: 780 ( 10.55%) in 8.385053 sec
    2013-07-16 13:14 - OK:  93, FAIL: 779 ( 10.67%) in 7.853702 sec
    2013-07-16 14:42 - OK:  94, FAIL: 778 ( 10.78%) in 8.509913 sec
    2013-07-16 16:07 - OK:  97, FAIL: 775 ( 11.12%) in 8.507561 sec
    2013-07-16 16:15 - OK:  98, FAIL: 781 ( 11.15%) in 7.904139 sec
    2013-07-16 16:42 - OK:  99, FAIL: 780 ( 11.26%) in 8.926196 sec
    2013-07-16 18:35 - OK:  98, FAIL: 781 ( 11.15%) in 8.392457 sec
    2013-07-16 18:54 - OK:  98, FAIL: 781 ( 11.15%) in 12.805801 sec
    2013-07-16 18:56 - OK: 102, FAIL: 777 ( 11.60%) in 9.911134 sec
    2013-07-16 19:01 - OK: 105, FAIL: 774 ( 11.95%) in 10.019737 sec
    2013-07-16 19:05 - OK: 108, FAIL: 771 ( 12.29%) in 11.494485 sec
    2013-07-16 19:16 - OK: 109, FAIL: 770 ( 12.40%) in 11.9682 sec
    2013-07-17 16:32 - OK: 109, FAIL: 770 ( 12.40%) in 10.299158 sec
    2013-07-17 16:38 - OK: 112, FAIL: 767 ( 12.74%) in 10.670618 sec
    2013-07-17 17:06 - OK: 120, FAIL: 759 ( 13.65%) in 10.038851 sec
    2013-07-17 17:22 - OK: 136, FAIL: 743 ( 15.47%) in 16.243514 sec
    2013-07-17 17:32 - OK: 141, FAIL: 738 ( 16.04%) in 8.048432 sec
    2013-07-17 17:36 - OK: 142, FAIL: 737 ( 16.15%) in 8.33143 sec
    2013-07-17 17:52 - OK: 142, FAIL: 737 ( 16.15%) in 10.476636 sec
    2013-07-17 18:07 - OK: 148, FAIL: 731 ( 16.84%) in 12.988215 sec
    2013-07-17 18:13 - OK: 149, FAIL: 730 ( 16.95%) in 8.944999 sec
    2013-07-17 18:22 - OK: 150, FAIL: 729 ( 17.06%) in 10.448631 sec
    2013-07-18 08:27 - OK: 159, FAIL: 720 ( 18.09%) in 10.232866 sec
    2013-07-18 08:35 - OK: 161, FAIL: 718 ( 18.32%) in 11.16733 sec
    2013-07-18 10:06 - OK: 162, FAIL: 717 ( 18.43%) in 11.850355 sec
    2013-07-18 10:19 - OK: 166, FAIL: 713 ( 18.89%) in 10.326044 sec
    2013-07-18 10:23 - OK: 171, FAIL: 708 ( 19.45%) in 12.072887 sec
    2013-07-18 10:34 - OK: 167, FAIL: 712 ( 19.00%) in 10.106932 sec
    2013-07-18 10:41 - OK: 168, FAIL: 711 ( 19.11%) in 10.893242 sec
    2013-07-18 11:00 - OK: 170, FAIL: 709 ( 19.34%) in 11.192021 sec
    2013-07-18 11:14 - OK: 171, FAIL: 708 ( 19.45%) in 11.567508 sec
    2013-07-18 11:28 - OK: 175, FAIL: 704 ( 19.91%) in 14.408353 sec
    2013-07-18 11:35 - OK: 176, FAIL: 703 ( 20.02%) in 11.210391 sec
    2013-07-24 14:01 - OK: 175, FAIL: 695 ( 20.11%) in 18.63396 sec
    2013-07-24 14:13 - OK: 176, FAIL: 694 ( 20.23%) in 12.192428 sec
    2013-07-24 14:18 - OK: 178, FAIL: 692 ( 20.46%) in 14.654108 sec
    2013-07-24 14:26 - OK: 177, FAIL: 693 ( 20.34%) in 13.426466 sec
    2013-07-24 14:29 - OK: 178, FAIL: 692 ( 20.46%) in 13.650246 sec
    2013-07-24 15:00 - OK: 178, FAIL: 692 ( 20.46%) in 19.137262 sec
    2013-07-24 15:17 - OK: 179, FAIL: 691 ( 20.57%) in 16.386203 sec
    2013-07-24 15:26 - OK: 181, FAIL: 689 ( 20.80%) in 11.713727 sec
    2013-07-24 15:39 - OK: 185, FAIL: 685 ( 21.26%) in 14.662159 sec
    2013-07-24 15:42 - OK: 190, FAIL: 680 ( 21.84%) in 15.433197 sec
    2013-07-24 15:47 - OK: 194, FAIL: 676 ( 22.30%) in 16.419683 sec
    2013-07-24 15:54 - OK: 196, FAIL: 674 ( 22.53%) in 15.670596 sec
    2013-07-24 16:08 - OK: 204, FAIL: 666 ( 23.45%) in 15.106542 sec
    2013-07-24 16:08 - OK: 204, FAIL: 666 ( 23.45%) in 15.106542 sec
    2013-07-24 16:15 - OK: 215, FAIL: 655 ( 24.71%) in 19.018465 sec
    2013-07-24 16:22 - OK: 225, FAIL: 645 ( 25.86%) in 14.133853 sec
    2013-07-24 16:28 - OK: 230, FAIL: 640 ( 26.44%) in 13.04479 sec
    2013-07-24 16:38 - OK: 234, FAIL: 636 ( 26.90%) in 10.433795 sec
    2013-07-24 17:21 - OK: 240, FAIL: 630 ( 27.59%) in 17.440013 sec
    2013-07-24 19:15 - OK: 248, FAIL: 622 ( 28.51%) in 19.040788 sec
    2013-07-25 10:16 - OK: 249, FAIL: 621 ( 28.62%) in 19.670311 sec
    2013-07-25 10:26 - OK: 251, FAIL: 619 ( 28.85%) in 16.824055 sec
    2013-07-25 10:31 - OK: 252, FAIL: 618 ( 28.97%) in 18.527572 sec
    2013-07-25 10:44 - OK: 252, FAIL: 618 ( 28.97%) in 16.030742 sec
    2013-07-25 10:57 - OK: 254, FAIL: 616 ( 29.20%) in 14.63103 sec
    2013-07-25 11:01 - OK: 256, FAIL: 614 ( 29.43%) in 18.734839 sec
    2013-07-25 11:14 - OK: 259, FAIL: 611 ( 29.77%) in 10.463899 sec
    2013-07-25 11:19 - OK: 263, FAIL: 607 ( 30.23%) in 14.052636 sec
    2013-07-28 19:31 - OK: 270, FAIL: 609 ( 30.72%) in 15.547074 sec
    2013-08-02 02:50 - OK: 263, FAIL: 616 ( 29.92%) in 11.517442 sec
    2013-08-02 02:56 - OK: 263, FAIL: 616 ( 29.92%) in 12.176088 sec
    2013-08-02 03:06 - OK: 265, FAIL: 614 ( 30.15%) in 10.450664 sec
    2013-08-08 08:39 - OK: 272, FAIL: 598 ( 31.26%) in 16.69513 sec
    2013-08-08 09:02 - OK: 278, FAIL: 592 ( 31.95%) in 18.286771 sec
    2013-08-08 16:06 - OK: 286, FAIL: 584 ( 32.87%) in 18.308893 sec
    2013-08-13 08:06 - OK: 286, FAIL: 584 ( 32.87%) in 10.755869 sec
    2013-08-14 07:08 - OK: 289, FAIL: 581 ( 33.22%) in 11.362161 sec
    2013-08-14 07:16 - OK: 294, FAIL: 576 ( 33.79%) in 14.559224 sec
    2013-08-15 16:30 - OK: 300, FAIL: 585 ( 33.90%) in 23.735736 sec
    2013-08-15 16:31 - OK: 300, FAIL: 585 ( 33.90%) in 19.1201 sec
    2013-08-20 17:49 - OK: 314, FAIL: 573 ( 35.40%) in 22.179679 sec
    2013-08-21 10:18 - OK: 315, FAIL: 572 ( 35.51%) in 23.075873 sec
    2013-08-21 19:10 - OK: 321, FAIL: 566 ( 36.19%) in 24.825519 sec
    2013-08-21 19:31 - OK: 329, FAIL: 558 ( 37.09%) in 25.736398 sec
    2013-08-22 08:31 - OK: 331, FAIL: 556 ( 37.32%) in 26.518253 sec
    2013-08-22 09:03 - OK: 342, FAIL: 545 ( 38.56%) in 25.247362 sec
    2013-08-23 11:31 - OK: 344, FAIL: 545 ( 38.70%) in 26.732798 sec
    2013-08-23 18:44 - OK: 349, FAIL: 540 ( 39.26%) in 38.798359 sec
    2013-08-23 19:10 - OK: 353, FAIL: 536 ( 39.71%) in 30.59785 sec
    2013-08-25 12:00 - OK: 356, FAIL: 533 ( 40.04%) in 27.650996 sec
    2013-08-25 17:00 - OK: 359, FAIL: 530 ( 40.38%) in 28.395332 sec
    2013-09-01 21:45 - OK: 424, FAIL: 467 ( 47.59%) in 38.840729 sec
    2013-09-03 03:29 - OK: 427, FAIL: 465 ( 47.87%) in 40.600417 sec

Contribution
------------

Any patches may accept with review. Please send us patches by github p-r.
This project stands on bazar model. I give collabo priv if you want :)

