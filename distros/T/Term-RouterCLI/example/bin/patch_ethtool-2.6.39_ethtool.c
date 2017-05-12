*** ethtool.c.orig	2011-06-01 13:56:02.000000000 -0600
--- ethtool.c	2011-06-06 22:48:55.000000000 -0600
***************
*** 2797,2803 ****
  
  	n_stats = drvinfo.n_stats;
  	if (n_stats < 1) {
! 		fprintf(stderr, "no stats available\n");
  		return 94;
  	}
  
--- 2797,2803 ----
  
  	n_stats = drvinfo.n_stats;
  	if (n_stats < 1) {
! 	  //fprintf(stderr, "no stats available\n");
  		return 94;
  	}
  
