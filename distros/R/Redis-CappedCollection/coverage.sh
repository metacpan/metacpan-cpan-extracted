cover -delete

#find t -name \*.t -print -exec perl -MDevel::Cover {} \;

perl -MDevel::Cover example.pl

perl -MDevel::Cover t/00_compile.t
perl -MDevel::Cover xt/author/92_vars.t
perl -MDevel::Cover xt/author/93_versions.t
perl -MDevel::Cover xt/author/94_fixme.t
perl -MDevel::Cover xt/author/95_critic.t
perl -MDevel::Cover xt/release/96_kwalitee.t
perl -MDevel::Cover xt/release/97_distribution.t
perl -MDevel::Cover xt/release/98_pod.t
perl -MDevel::Cover xt/release/99_pod_coverage.t

perl -MDevel::Cover t/00_CappedCollection/00_compile.t
perl -MDevel::Cover t/00_CappedCollection/01_new.t
perl -MDevel::Cover t/00_CappedCollection/02_insert.t
perl -MDevel::Cover t/00_CappedCollection/03_update.t
perl -MDevel::Cover t/00_CappedCollection/04_receive.t
perl -MDevel::Cover t/00_CappedCollection/05_collection_info.t
perl -MDevel::Cover t/00_CappedCollection/06_pop_oldest.t
perl -MDevel::Cover t/00_CappedCollection/07_exists.t
perl -MDevel::Cover t/00_CappedCollection/08_lists.t
perl -MDevel::Cover t/00_CappedCollection/09_drop_collection.t
perl -MDevel::Cover t/00_CappedCollection/10_quit.t
perl -MDevel::Cover t/00_CappedCollection/11_max_datasize.t
perl -MDevel::Cover t/00_CappedCollection/12_last_errorcode.t
perl -MDevel::Cover t/00_CappedCollection/13_name.t
perl -MDevel::Cover t/00_CappedCollection/15_cleanup_bytes.t
perl -MDevel::Cover t/00_CappedCollection/17_cleanup_items.t
perl -MDevel::Cover t/00_CappedCollection/18_info.t
perl -MDevel::Cover t/00_CappedCollection/19_drop.t
perl -MDevel::Cover t/00_CappedCollection/20_cleaning.t
perl -MDevel::Cover t/00_CappedCollection/21_rollback.t
perl -MDevel::Cover t/00_CappedCollection/22_alarm.t
perl -MDevel::Cover t/00_CappedCollection/23_cleaning_bench.t
perl -MDevel::Cover t/00_CappedCollection/24_timeout.t
perl -MDevel::Cover t/00_CappedCollection/25_cleaning_correctness.t
perl -MDevel::Cover t/00_CappedCollection/26_script_variable_protection.t
perl -MDevel::Cover t/00_CappedCollection/27_fork.t
perl -MDevel::Cover xt/release/00_CappedCollection/98_pod.t
perl -MDevel::Cover xt/release/00_CappedCollection/99_pod_coverage.t

cover
