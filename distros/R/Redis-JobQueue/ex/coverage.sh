cd ..
cover -delete

#find t -name \*.t -print -exec perl -MDevel::Cover {} \;

perl -MDevel::Cover example.pl

#perl -MDevel::Cover t/00_compile.t
perl -MDevel::Cover xt/author/92_vars.t
perl -MDevel::Cover xt/author/93_versions.t
perl -MDevel::Cover xt/author/94_fixme.t
perl -MDevel::Cover xt/author/95_critic.t
perl -MDevel::Cover xt/release/96_kwalitee.t
perl -MDevel::Cover xt/release/97_distribution.t
perl -MDevel::Cover xt/release/98_pod.t
perl -MDevel::Cover xt/release/99_pod_coverage.t

perl -MDevel::Cover t/00_Job/00_compile.t
perl -MDevel::Cover t/00_Job/01_new.t
perl -MDevel::Cover t/00_Job/02_accessor.t
perl -MDevel::Cover t/00_Job/03_modified.t
perl -MDevel::Cover t/00_Job/04_job_attributes.t
perl -MDevel::Cover t/00_Job/05_meta_data.t
perl -MDevel::Cover xt/release/00_Job/98_pod.t
perl -MDevel::Cover xt/release/00_Job/99_pod_coverage.t

perl -MDevel::Cover t/01_JobQueue/00_compile.t
perl -MDevel::Cover t/01_JobQueue/01_new.t
perl -MDevel::Cover t/01_JobQueue/02_add_job.t
perl -MDevel::Cover t/01_JobQueue/04_load_job.t
perl -MDevel::Cover t/01_JobQueue/05_get_next_job.t
perl -MDevel::Cover t/01_JobQueue/06_update_job.t
perl -MDevel::Cover t/01_JobQueue/07_delete_job.t
perl -MDevel::Cover t/01_JobQueue/08_job_ids.t
perl -MDevel::Cover t/01_JobQueue/09_quit.t
perl -MDevel::Cover t/01_JobQueue/10_max_datasize.t
perl -MDevel::Cover t/01_JobQueue/11_last_errorcode.t
perl -MDevel::Cover t/01_JobQueue/12_timeout.t
perl -MDevel::Cover t/01_JobQueue/13_get_job_meta_fields.t
perl -MDevel::Cover t/01_JobQueue/14_get_job_data.t
perl -MDevel::Cover t/01_JobQueue/15_queue_status.t
perl -MDevel::Cover t/01_JobQueue/16_utf8.t
perl -MDevel::Cover xt/release/01_JobQueue/98_pod.t
perl -MDevel::Cover xt/release/01_JobQueue/99_pod_coverage.t

cover
