

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <time.h>

#define RRD_EXPORT_DEPRECATED
#include <rrd.h>

#ifndef RRD_READONLY
/* these are defined in rrd_tool.h and unavailable for use outside of rrdtool */
#define RRD_READONLY    (1<<0)
#define RRD_READWRITE   (1<<1)
#define RRD_CREAT       (1<<2)
#define RRD_READAHEAD   (1<<3)
#define RRD_COPY        (1<<4)
#define RRD_EXCL        (1<<5)
#endif

#ifndef RRD_VERSION4
#define RRD_VERSION4   "0004"
#endif

/* rrd_random() appears only in rrdtool-1.4, and we need backward
   compatibility */
static long tweak_rrd_random(void) {
    static int rand_init = 0;
    if (!rand_init) {
        srand((unsigned int) time(NULL) + (unsigned int) getpid());
        rand_init++;
    }
    return rand();
}


/* this is not yet implemented in RRDtool -- with the hopes for a
   better future */
#if defined(RRD_TOOL_VERSION) && RRD_TOOL_VERSION > 10040999
#define HAS_RRD_RPN_COMPACT2STR
#else
/* extract from rrd_format.c */
#define converter(VV,VVV)                       \
   if (strcmp(#VV, string) == 0) return VVV;

static enum cf_en rrd_cf_conv(
    const char *string)
{

    converter(AVERAGE, CF_AVERAGE)
        converter(MIN, CF_MINIMUM)
        converter(MAX, CF_MAXIMUM)
        converter(LAST, CF_LAST)
        converter(HWPREDICT, CF_HWPREDICT)
        converter(MHWPREDICT, CF_MHWPREDICT)
        converter(DEVPREDICT, CF_DEVPREDICT)
        converter(SEASONAL, CF_SEASONAL)
        converter(DEVSEASONAL, CF_DEVSEASONAL)
        converter(FAILURES, CF_FAILURES)
        rrd_set_error("unknown consolidation function '%s'", string);
    return (enum cf_en)(-1);
}
#endif

/* copied from rrd_restore.c -- to be independent from MMAP */
static void local_rrd_free (rrd_t *rrd)
{
    free(rrd->live_head);
    free(rrd->stat_head);
    free(rrd->ds_def);
    free(rrd->rra_def);
    free(rrd->rra_ptr);
    free(rrd->pdp_prep);
    free(rrd->cdp_prep);
    free(rrd->rrd_value);
    free(rrd);
}


MODULE = RRD::Tweak


void
_load_file(HV *self, char *filename)
  INIT:
    rrd_value_t  my_cdp;
    off_t        rra_base, rra_start, rra_next;
    rrd_file_t   *rrd_file;
    rrd_t        rrd;
    rrd_value_t  value;
    unsigned int i, ii, ix, iii;
    AV           *ds_list;
    AV           *rradef_list;
    AV           *cdp_data;
    AV           *cdp_prep_list;
  CODE:
  {
      /* This function is derived from rrd_dump.c */

      rrd_init(&rrd);

      rrd_file = rrd_open(filename, &rrd, RRD_READONLY | RRD_READAHEAD);
      if (rrd_file == NULL) {
          rrd_free(&rrd);
          croak("Cannot open RRD file \"%s\": %s", filename, strerror(errno));
      }

      # Read the static header
      hv_store(self, "version", 7, newSVuv(atoi(rrd.stat_head->version)), 0);
      hv_store(self, "pdp_step", 8, newSVuv(rrd.stat_head->pdp_step), 0);

      # Read the live header
      hv_store(self, "last_up", 7, newSVuv(rrd.live_head->last_up), 0);

      /* process datasources */
      ds_list = newAV();
      for (i = 0; i < rrd.stat_head->ds_cnt; i++) {
          HV *ds_params;
          ds_params = newHV();

          hv_store(ds_params, "name", 4, newSVpv(rrd.ds_def[i].ds_nam, 0), 0);
          hv_store(ds_params, "type", 4, newSVpv(rrd.ds_def[i].dst, 0), 0);

          if( strcmp(rrd.ds_def[i].dst, "COMPUTE") != 0 ) {

              /* heartbit */
              hv_store(ds_params, "hb", 2,
                       newSVuv(rrd.ds_def[i].par[DS_mrhb_cnt].u_cnt), 0);

              /* min and max */
              hv_store(ds_params, "min", 3,
                       newSVnv(rrd.ds_def[i].par[DS_min_val].u_val), 0);
              hv_store(ds_params, "max", 3,
                       newSVnv(rrd.ds_def[i].par[DS_max_val].u_val), 0);

          } else {   /* COMPUTE */
#ifdef HAS_RRD_RPN_COMPACT2STR
              char     *str = NULL;
              /* at the moment there's only non-public rpn_compact2str
              in rrdtool */
              rrd_rpn_compact2str((rpn_cdefds_t *)
                                  &(rrd.ds_def[i].par[DS_cdef]),
                                  rrd.ds_def, &str);
              hv_store(ds_params, "rpn", 3, newSVpv(str,0), 0);
              free(str);
#else
              rrd_free(&rrd);
              croak("COMPUTE datasource is not supported by RRD::Tweak");
#endif
          }

          /* last DS value is stored as string */
          hv_store(ds_params, "last_ds", 7,
                   newSVpv(rrd.pdp_prep[i].last_ds, 0), 0);

          /* scratch value */
          hv_store(ds_params, "scratch_value", 13,
                   newSVnv(rrd.pdp_prep[i].scratch[PDP_val].u_val), 0);

          /* unknown seconds */
          hv_store(ds_params, "unknown_sec", 11,
                   newSVuv(rrd.pdp_prep[i].scratch[PDP_unkn_sec_cnt].u_cnt), 0);

          /* done with this DS -- store it into ds_list array */
          av_push(ds_list, newRV_noinc((SV *) ds_params));
      }

      /* done with datasources -- attach ds_list as $self->{ds} */
      hv_store(self, "ds", 2, newRV_noinc((SV *) ds_list), 0);


      /* process RRA's */
      rradef_list = newAV();
      cdp_prep_list = newAV();
      cdp_data = newAV();

      rra_base = rrd_file->header_len;
      rra_next = rra_base;
      for (i = 0; i < rrd.stat_head->rra_cnt; i++) {
          /* hash with RRA attributes */
          HV *rra_params = newHV();
          /* array with CDP preparation values for each DS */
          AV *rra_cdp_prep = newAV();
          /* array of CDP rows */
          AV *rra_cdp_rows = newAV();

          /* process RRA definition */

          rra_start = rra_next;
          rra_next += (rrd.stat_head->ds_cnt
                       * rrd.rra_def[i].row_cnt * sizeof(rrd_value_t));

          hv_store(rra_params, "cf", 2,
                   newSVpv(rrd.rra_def[i].cf_nam, 0), 0);

          hv_store(rra_params, "pdp_per_row", 11,
                   newSVuv(rrd.rra_def[i].pdp_cnt), 0);

          /* RRA parameters specific to each CF */
          switch (rrd_cf_conv(rrd.rra_def[i].cf_nam)) {

          case CF_HWPREDICT:
          case CF_MHWPREDICT:
              hv_store(rra_params, "hw_alpha", 8,
                       newSVnv(rrd.rra_def[i].par[RRA_hw_alpha].u_val), 0);
              hv_store(rra_params, "hw_beta", 7,
                       newSVnv(rrd.rra_def[i].par[RRA_hw_beta].u_val), 0);
              hv_store(rra_params, "dependent_rra_idx", 17,
                       newSVuv(rrd.rra_def[i].par[
                                   RRA_dependent_rra_idx].u_cnt), 0);
            break;

          case CF_SEASONAL:
          case CF_DEVSEASONAL:
              hv_store(rra_params, "seasonal_gamma", 14,
                       newSVnv(rrd.rra_def[i].par[RRA_seasonal_gamma].u_val),
                       0);
              hv_store(rra_params, "seasonal_smooth_idx", 19,
                       newSVuv(rrd.rra_def[i].par[
                                   RRA_seasonal_smooth_idx].u_cnt), 0);
              if (atoi(rrd.stat_head->version) >= 4) {
                  hv_store(rra_params, "smoothing_window", 16,
                           newSVnv(rrd.rra_def[i].par[
                                       RRA_seasonal_smoothing_window].u_val),0);
              }

              hv_store(rra_params, "dependent_rra_idx", 17,
                       newSVuv(rrd.rra_def[i].par[
                                   RRA_dependent_rra_idx].u_cnt), 0);
            break;

          case CF_FAILURES:
              hv_store(rra_params, "delta_pos", 9,
                       newSVnv(rrd.rra_def[i].par[RRA_delta_pos].u_val), 0);
              hv_store(rra_params, "delta_neg", 9,
                       newSVnv(rrd.rra_def[i].par[RRA_delta_neg].u_val), 0);
              hv_store(rra_params, "window_len", 10,
                       newSVuv(rrd.rra_def[i].par[RRA_window_len].u_cnt), 0);
              hv_store(rra_params, "failure_threshold", 17,
                       newSVuv(rrd.rra_def[i].par[
                                   RRA_failure_threshold].u_cnt), 0);

              /* fall thru */
          case CF_DEVPREDICT:
              hv_store(rra_params, "dependent_rra_idx", 17,
                       newSVuv(rrd.rra_def[i].par[
                                   RRA_dependent_rra_idx].u_cnt), 0);
              break;

          case CF_AVERAGE:
          case CF_MAXIMUM:
          case CF_MINIMUM:
          case CF_LAST:
          default:
              hv_store(rra_params, "xff", 3,
                       newSVnv(rrd.rra_def[i].par[RRA_cdp_xff_val].u_val), 0);
              break;
          }

          /* extract cdp_prep for each DS for this RRA */
          for (ii = 0; ii < rrd.stat_head->ds_cnt; ii++) {
              unsigned long uival;
              cdp_prep_t *cur_cdp_prep =
                  rrd.cdp_prep + (i * rrd.stat_head->ds_cnt + ii);

              HV *ds_cdp_prep = newHV();  /* per-DS CDP preparaion values */

              switch (rrd_cf_conv(rrd.rra_def[i].cf_nam)) {

              case CF_HWPREDICT:
              case CF_MHWPREDICT:
                  value = cur_cdp_prep->scratch[CDP_hw_intercept].u_val;
                  hv_store(ds_cdp_prep, "intercept", 9, newSVnv(value), 0);

                  value = cur_cdp_prep->scratch[CDP_hw_last_intercept].u_val;
                  hv_store(ds_cdp_prep, "last_intercept", 14,
                           newSVnv(value), 0);

                  value = cur_cdp_prep->scratch[CDP_hw_slope].u_val;
                  hv_store(ds_cdp_prep, "slope", 5, newSVnv(value), 0);

                  value = cur_cdp_prep->scratch[CDP_hw_last_slope].u_val;
                  hv_store(ds_cdp_prep, "last_slope", 10, newSVnv(value), 0);


                  uival = cur_cdp_prep->scratch[CDP_null_count].u_cnt;
                  hv_store(ds_cdp_prep, "null_count", 10, newSVuv(uival), 0);

                  uival = cur_cdp_prep->scratch[CDP_last_null_count].u_cnt;
                  hv_store(ds_cdp_prep, "last_null_count", 15,
                           newSVuv(uival), 0);
                  break;

              case CF_SEASONAL:
              case CF_DEVSEASONAL:
                  value = cur_cdp_prep->scratch[CDP_hw_seasonal].u_val;
                  hv_store(ds_cdp_prep, "seasonal", 8, newSVnv(value), 0);

                  value = cur_cdp_prep->scratch[CDP_hw_last_seasonal].u_val;
                  hv_store(ds_cdp_prep, "last_seasonal", 13, newSVnv(value), 0);

                  uival = cur_cdp_prep->scratch[CDP_init_seasonal].u_cnt;
                  hv_store(ds_cdp_prep, "init_flag", 9,
                           newSVuv(uival), 0);
                  break;

              case CF_DEVPREDICT:
                  break;

              case CF_FAILURES:
              {
                  unsigned short vidx;
                  char *violations_array =
                      (char *) ((void *) cur_cdp_prep->scratch);

                  AV *history_array = newAV();

                  for (vidx = 0;
                       vidx < rrd.rra_def[i].par[RRA_window_len].u_cnt;
                       vidx++) {
                      av_push(history_array, newSVuv(violations_array[vidx]));
                  }

                  hv_store(ds_cdp_prep, "history", 7,
                           newRV_noinc((SV *) history_array), 0);
              }

              break;

              case CF_AVERAGE:
              case CF_MAXIMUM:
              case CF_MINIMUM:
              case CF_LAST:
              default:
                  value = cur_cdp_prep->scratch[CDP_val].u_val;
                  hv_store(ds_cdp_prep, "value", 5, newSVnv(value), 0);

                  hv_store(ds_cdp_prep, "unknown_datapoints", 18,
                           newSVuv(
                               cur_cdp_prep->scratch[CDP_unkn_pdp_cnt].u_cnt),
                           0);
                  break;
              }

              /* done with this DS CDP. store it into rra_cdp_prep array */
              av_push(rra_cdp_prep, newRV_noinc((SV *) ds_cdp_prep));
          }

          /* done with all datasources. Store rra_cdp_prep into cdp_prep_list */
          av_push(cdp_prep_list, newRV_noinc((SV *) rra_cdp_prep));


          /* done with RRA definition, attach it to rradef_list array */
          av_push(rradef_list, newRV_noinc((SV *) rra_params));

          /* extract the RRA data */
          rrd_seek(rrd_file, (rra_start + (rrd.rra_ptr[i].cur_row + 1)
                              * rrd.stat_head->ds_cnt
                              * sizeof(rrd_value_t)), SEEK_SET);
          ii = rrd.rra_ptr[i].cur_row;
          for (ix = 0; ix < rrd.rra_def[i].row_cnt; ix++) {
              ii++;
              AV *cdp_row = newAV();

              if (ii >= rrd.rra_def[i].row_cnt) {
                  rrd_seek(rrd_file, rra_start, SEEK_SET);
                  ii = 0; /* wrap if max row cnt is reached */
              }

              for (iii = 0; iii < rrd.stat_head->ds_cnt; iii++) {
                  rrd_read(rrd_file, &my_cdp, sizeof(rrd_value_t) * 1);
                  av_push(cdp_row, newSVnv(my_cdp));
              }

              av_push(rra_cdp_rows, newRV_noinc((SV *) cdp_row));
          }

          /* done with this RRA. Add it to cdp_data array */
          av_push(cdp_data, newRV_noinc((SV *) rra_cdp_rows));
      }

      /* done with RRA processing -- attach rradef_list as $self->{rra} */
      hv_store(self, "rra", 3, newRV_noinc((SV *) rradef_list), 0);

      /* attach cdp_prep_list as $self->{cdp_prep} */
      hv_store(self, "cdp_prep", 8, newRV_noinc((SV *) cdp_prep_list), 0);

      /* attach cdp_data as $self->{cdp_data} */
      hv_store(self, "cdp_data", 8, newRV_noinc((SV *) cdp_data), 0);

      rrd_free(&rrd);
      rrd_close(rrd_file);
  }






void
_save_file(HV *self, char *filename)
  INIT:
    rrd_t        *rrd;
    SV           **fetch_result;
    STRLEN       len;
    char         *ptr;
    unsigned int i, ii, iii, uival, rrd_file_version;
    rrd_value_t  value;
    unsigned int n_ds = 0; /* number of DS'es */
    unsigned int n_rra = 0; /* number of RRA's */
    int          fd;
    FILE         *fh;
    AV           *cdp_data_array;
    rrd_value_t  *row_buf;
  CODE:
  {
      /* This function is derived from rrd_restore.c
         We do not validate $self here and assume that $self->validate()
         was called before. */

      /* Open the file as early as possible. We overwrite and truncate
         any existing file. */

      fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0666);
      if (fd == -1) {
          croak("Cannot open %s for writing: %s", filename, strerror(errno));
      }

      fh = fdopen(fd, "wb");
      if (fh == NULL) {
          close(fd);
          croak("fdopen failed: %s", strerror(errno));
      }

      /* We translate all the header data into RRDtool native format.
         The CDP rows will be processed sequentially while writing to the file,
         so that we don't have to allocate memory for the whole data amount.
      */

      rrd = (rrd_t *) malloc(sizeof(rrd_t));
      if (rrd == NULL) {
          croak("save_file: malloc failed.");
      }
      memset(rrd, '\0', sizeof(rrd_t));

      rrd->stat_head = (stat_head_t *) malloc(sizeof(stat_head_t));
      if (rrd->stat_head == NULL) {
          free(rrd);
          croak("save_file: malloc failed.");
      }
      memset(rrd->stat_head, '\0', sizeof(stat_head_t));

      strncpy(rrd->stat_head->cookie, "RRD", sizeof(rrd->stat_head->cookie));
      rrd->stat_head->float_cookie = FLOAT_COOKIE;

      rrd->live_head = (live_head_t *) malloc(sizeof(live_head_t));
      if (rrd->live_head == NULL) {
          free(rrd->stat_head);
          free(rrd);
          croak("save_file: malloc failed.");
      }
      memset(rrd->live_head, '\0', sizeof(live_head_t));

      /* store the version. If $self->{version} is not 4, use 3 */
      fetch_result = hv_fetch(self, "version", 7, 0);
      ptr = NULL;
      if( fetch_result != NULL ) {
          uival = SvUV(*fetch_result);
          if( uival == 4 ) {
              rrd_file_version = 4;
              ptr = RRD_VERSION4;
          }
      }
      if( ptr == NULL ) {
          rrd_file_version = 3;
          ptr = RRD_VERSION3;
      }
      strncpy(rrd->stat_head->version, ptr, sizeof(rrd->stat_head->version));

      /* get $self->{pdp_step} */
      fetch_result = hv_fetch(self, "pdp_step", 8, 0);
      uival = SvUV(*fetch_result);
      rrd->stat_head->pdp_step = uival;

      /* get $self->{last_up} */
      fetch_result = hv_fetch(self, "last_up", 7, 0);
      uival = SvUV(*fetch_result);
      rrd->live_head->last_up = uival;

      /* get $self->{cdp_data} */
      fetch_result = hv_fetch(self, "cdp_data", 8, 0);
      cdp_data_array = (AV *)SvRV(*fetch_result);

      /* ds */
      {
          AV *ds_array;

          /* get $self->{ds} */
          fetch_result = hv_fetch(self, "ds", 2, 0);
          ds_array = (AV *)SvRV(*fetch_result);
          n_ds = av_len(ds_array) + 1;

          /* buffer of CDP row values for writing into the file */
          row_buf = (rrd_value_t *) malloc(sizeof(rrd_value_t) * n_ds);
          if( row_buf == NULL ) {
              local_rrd_free(rrd);
              croak("save_file: malloc failed.");
          }

          /* Allocate space for DS definitions */
          rrd->ds_def = (ds_def_t *) malloc(sizeof(ds_def_t) * n_ds);
          if( rrd->ds_def == NULL ) {
              local_rrd_free(rrd);
              croak("save_file: malloc failed.");
          }
          memset(rrd->ds_def, '\0', sizeof(ds_def_t)  * n_ds);

          /* Allocate pdp_prep space for DS definitions */
          rrd->pdp_prep = (pdp_prep_t *) malloc(sizeof(pdp_prep_t) * n_ds);
          if( rrd->pdp_prep == NULL ) {
              local_rrd_free(rrd);
              croak("save_file: malloc failed.");
          }
          memset(rrd->pdp_prep, '\0', sizeof(pdp_prep_t)  * n_ds);

          rrd->stat_head->ds_cnt = n_ds;

          for (i = 0; i < n_ds; i++) {
              HV *ds_params;
              ds_def_t *cur_ds_def = rrd->ds_def + i;
              pdp_prep_t *cur_pdp_prep = rrd->pdp_prep + i;

              fetch_result = av_fetch(ds_array, i, 0);
              ds_params = (HV *)SvRV(*fetch_result);

              /* DS name */
              fetch_result = hv_fetch(ds_params, "name", 4, 0);
              ptr = SvPV_nolen(*fetch_result);
              strncpy(cur_ds_def->ds_nam, ptr, sizeof(cur_ds_def->ds_nam));

              /* DS type */
              fetch_result = hv_fetch(ds_params, "type", 4, 0);
              ptr = SvPV_nolen(*fetch_result);
              strncpy(cur_ds_def->dst, ptr, sizeof(cur_ds_def->dst));

              if( strcmp(ptr, "COMPUTE") != 0 ) {

                  /* DS heartbit */
                  fetch_result = hv_fetch(ds_params, "hb", 2, 0);
                  uival = SvUV(*fetch_result);
                  cur_ds_def->par[DS_mrhb_cnt].u_cnt = uival;

                  /* DS min */
                  fetch_result = hv_fetch(ds_params, "min", 3, 0);
                  value = SvNV(*fetch_result);
                  cur_ds_def->par[DS_min_val].u_val = value;

                  /* DS max */
                  fetch_result = hv_fetch(ds_params, "max", 3, 0);
                  value = SvNV(*fetch_result);
                  cur_ds_def->par[DS_max_val].u_val = value;
              }
              else {   /* COMPUTE */
                  /* parseCDEF_DS() is not avaiable in librrd
                     public interface */
                  local_rrd_free(rrd);
                  croak("COMPUTE datasource is not supported by RRD::Tweak");
              }

              /* pdp_prep last_ds */
              fetch_result = hv_fetch(ds_params, "last_ds", 7, 0);
              ptr = SvPV_nolen(*fetch_result);
              strncpy(cur_pdp_prep->last_ds, ptr,
                      sizeof(cur_pdp_prep->last_ds));

              /* pdp_prep scratch_value */
              fetch_result = hv_fetch(ds_params, "scratch_value", 13, 0);
              value = SvNV(*fetch_result);
              cur_pdp_prep->scratch[PDP_val].u_val = value;

              /* pdp_prep unknown_sec */
              fetch_result = hv_fetch(ds_params, "unknown_sec", 11, 0);
              uival = SvUV(*fetch_result);
              cur_pdp_prep->scratch[PDP_unkn_sec_cnt].u_cnt = uival;
          }
          /* finished processinb DS definitions */
      }

      /* rra */
      {
          AV *rra_array;
          AV *cdp_prep_array;

          /* get $self->{rra} */
          fetch_result = hv_fetch(self, "rra", 3, 0);
          rra_array = (AV *)SvRV(*fetch_result);
          n_rra = av_len(rra_array) + 1;

          /* get $self->{cdp_prep} */
          fetch_result = hv_fetch(self, "cdp_prep", 8, 0);
          cdp_prep_array = (AV *)SvRV(*fetch_result);

          /* Allocate rra_def space for all RRA definitions */
          rrd->rra_def =
              (rra_def_t *) malloc(sizeof(rra_def_t) * n_rra);
          if( rrd->rra_def == NULL ) {
              local_rrd_free(rrd);
              croak("save_file: malloc failed.");
          }
          memset(rrd->rra_def, '\0', sizeof(rra_def_t) * n_rra);

          /* Allocate cdp_prep_t */
          rrd->cdp_prep =
              (cdp_prep_t *) malloc(sizeof(cdp_prep_t) * n_ds * n_rra);
          if( rrd->cdp_prep  == NULL ) {
              local_rrd_free(rrd);
              croak("save_file: malloc failed.");
          }
          memset(rrd->cdp_prep, '\0', sizeof(cdp_prep_t) * n_ds * n_rra);

          /* Allocate rra_ptr_t */
          rrd->rra_ptr =
              (rra_ptr_t *) malloc(sizeof(rra_ptr_t) * n_rra);
          if( rrd->rra_ptr == NULL ) {
              local_rrd_free(rrd);
              croak("save_file: malloc failed.");
          }
          memset(rrd->rra_ptr, '\0', sizeof(rra_ptr_t) * n_rra);

          rrd->stat_head->rra_cnt = n_rra;

          for (i = 0; i < n_rra; i++)  {
              const char *cf;
              unsigned int cf_num;
              HV *rra_params;
              AV *rra_cdp_prep_array;
              AV *rra_cdp_data_array;

              rra_def_t *cur_rra_def = rrd->rra_def + i;

              /* get rra_params hash from rra_array->[i] */
              fetch_result = av_fetch(rra_array, i, 0);
              rra_params = (HV *)SvRV(*fetch_result);

              /* get rra_cdp_prep_array from cdp_prep_array->[i] */
              fetch_result = av_fetch(cdp_prep_array, i, 0);
              rra_cdp_prep_array = (AV *)SvRV(*fetch_result);

              /* Calculate RRA row count from length($self->{cdp_data}[$i]) */
              fetch_result = av_fetch(cdp_data_array, i, 0);
              rra_cdp_data_array = (AV *)SvRV(*fetch_result);
              cur_rra_def->row_cnt = av_len(rra_cdp_data_array) + 1;

              /* Set the RRA pointer to a random location */
              rrd->rra_ptr[i].cur_row =
                  tweak_rrd_random() % cur_rra_def->row_cnt;

              /* RRA cf */
              fetch_result = hv_fetch(rra_params, "cf", 2, 0);
              cf = SvPV_nolen(*fetch_result);
              strncpy(cur_rra_def->cf_nam, cf, sizeof(cur_rra_def->cf_nam));
              cf_num = rrd_cf_conv(cf);

              /* RRA pdp_per_row */
              fetch_result = hv_fetch(rra_params, "pdp_per_row", 11, 0);
              uival = SvUV(*fetch_result);
              cur_rra_def->pdp_cnt = uival;

              /* RRA parameters specific to each CF */
              switch (cf_num) {

              case CF_MHWPREDICT:
                  /* MHWPREDICT causes Version 4 */
                  strcpy(rrd->stat_head->version, RRD_VERSION4);
                  rrd_file_version = 4;

              case CF_HWPREDICT:
                  fetch_result = hv_fetch(rra_params, "hw_alpha", 8, 0);
                  value = SvNV(*fetch_result);
                  cur_rra_def->par[RRA_hw_alpha].u_val = value;

                  fetch_result = hv_fetch(rra_params, "hw_beta", 7, 0);
                  value = SvNV(*fetch_result);
                  cur_rra_def->par[RRA_hw_beta].u_val = value;

                  fetch_result =
                      hv_fetch(rra_params, "dependent_rra_idx", 17, 0);
                  uival = SvUV(*fetch_result);
                  cur_rra_def->par[RRA_dependent_rra_idx].u_cnt = uival;

                  break;

              case CF_SEASONAL:
              case CF_DEVSEASONAL:
                  fetch_result = hv_fetch(rra_params, "seasonal_gamma", 14, 0);
                  value = SvNV(*fetch_result);
                  cur_rra_def->par[RRA_seasonal_gamma].u_val = value;

                  fetch_result =
                      hv_fetch(rra_params, "seasonal_smooth_idx", 19, 0);
                  uival = SvUV(*fetch_result);
                  cur_rra_def->par[RRA_seasonal_smooth_idx].u_cnt = uival;


                  fetch_result =
                      hv_fetch(rra_params, "smoothing_window", 16, 0);
                  if( fetch_result != NULL ) {
                      value = SvNV(*fetch_result);
                      cur_rra_def->par[RRA_seasonal_smoothing_window].u_val =
                          value;
                      /* smoothing-window causes Version 4 */
                      strcpy(rrd->stat_head->version, RRD_VERSION4);
                      rrd_file_version = 4;
                  }

                  fetch_result =
                      hv_fetch(rra_params, "dependent_rra_idx", 17, 0);
                  uival = SvUV(*fetch_result);
                  cur_rra_def->par[RRA_dependent_rra_idx].u_cnt = uival;

                  break;

              case CF_FAILURES:
                  fetch_result = hv_fetch(rra_params, "delta_pos", 9, 0);
                  value = SvNV(*fetch_result);
                  cur_rra_def->par[RRA_delta_pos].u_val = value;

                  fetch_result = hv_fetch(rra_params, "delta_neg", 9, 0);
                  value = SvNV(*fetch_result);
                  cur_rra_def->par[RRA_delta_neg].u_val = value;

                  fetch_result = hv_fetch(rra_params, "window_len", 10, 0);
                  uival = SvUV(*fetch_result);
                  cur_rra_def->par[RRA_window_len].u_cnt = uival;

                  fetch_result =
                      hv_fetch(rra_params, "failure_threshold", 17, 0);
                  uival = SvUV(*fetch_result);
                  cur_rra_def->par[RRA_failure_threshold].u_cnt = uival;

                  /* fall thru */

              case CF_DEVPREDICT:
                  fetch_result =
                      hv_fetch(rra_params, "dependent_rra_idx", 17, 0);
                  uival = SvUV(*fetch_result);
                  cur_rra_def->par[RRA_dependent_rra_idx].u_cnt = uival;

                  break;

              case CF_AVERAGE:
              case CF_MAXIMUM:
              case CF_MINIMUM:
              case CF_LAST:
              default:
                  fetch_result = hv_fetch(rra_params, "xff", 3, 0);
                  value = SvNV(*fetch_result);
                  cur_rra_def->par[RRA_cdp_xff_val].u_val = value;
                  break;
              }

              /* retrieve cdp_prep for each DS for this RRA */

              for (ii = 0; ii < n_ds; ii++) {
                  cdp_prep_t *cur_cdp_prep = rrd->cdp_prep + (i * n_ds + ii);
                  HV *ds_cdp_prep;

                  /* get ds_cdp_prep hash from rra_cdp_prep_array->[ii] */
                  fetch_result = av_fetch(rra_cdp_prep_array, ii, 0);
                  ds_cdp_prep = (HV *)SvRV(*fetch_result);

                  /* cdp_prep parameters specific to each CF */
                  switch (cf_num) {

                  case CF_HWPREDICT:
                  case CF_MHWPREDICT:
                      fetch_result = hv_fetch(ds_cdp_prep, "intercept", 9, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_hw_intercept].u_val = value;

                      fetch_result =
                          hv_fetch(ds_cdp_prep, "last_intercept", 14, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_hw_last_intercept].u_val =
                          value;

                      fetch_result = hv_fetch(ds_cdp_prep, "slope", 5, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_hw_slope].u_val = value;

                      fetch_result =
                          hv_fetch(ds_cdp_prep, "last_slope", 10, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_hw_last_slope].u_val = value;

                      fetch_result = hv_fetch(ds_cdp_prep, "null_count", 10, 0);
                      uival = SvUV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_null_count].u_cnt = uival;


                      fetch_result =
                          hv_fetch(ds_cdp_prep, "last_null_count", 15, 0);
                      uival = SvUV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_last_null_count].u_cnt = uival;

                      break;

                  case CF_SEASONAL:
                  case CF_DEVSEASONAL:

                      fetch_result = hv_fetch(ds_cdp_prep, "seasonal", 8, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_hw_seasonal].u_val = value;

                      fetch_result =
                          hv_fetch(ds_cdp_prep, "last_seasonal", 13, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_hw_last_seasonal].u_val = value;

                      fetch_result = hv_fetch(ds_cdp_prep, "init_flag", 9, 0);
                      uival = SvUV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_init_seasonal].u_cnt = uival;

                      break;

                  case CF_DEVPREDICT:
                      break;

                  case CF_FAILURES:
                  {
                      unsigned short vidx, history_len;
                      char *violations_array =
                          (char *)((void *) cur_cdp_prep->scratch);

                      AV *history_array;
                      fetch_result = hv_fetch(ds_cdp_prep, "history", 7, 0);
                      history_array = (AV *)SvRV(*fetch_result);

                      history_len = av_len(history_array) + 1;

                      for (vidx = 0; vidx < history_len; vidx++) {
                          fetch_result = av_fetch(history_array, vidx, 0);
                          uival = SvUV(*fetch_result);
                          violations_array[vidx] = (char) uival;
                      }
                  }

                  break;

                  case CF_AVERAGE:
                  case CF_MAXIMUM:
                  case CF_MINIMUM:
                  case CF_LAST:
                  default:

                      fetch_result = hv_fetch(ds_cdp_prep, "value", 5, 0);
                      value = SvNV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_val].u_val = value;

                      fetch_result =
                          hv_fetch(ds_cdp_prep, "unknown_datapoints", 18, 0);
                      uival = SvUV(*fetch_result);
                      cur_cdp_prep->scratch[CDP_unkn_pdp_cnt].u_cnt = uival;

                      break;
                  }
              }
              /* Finished processing cdp_prep for each DS for this RRA. */
          }
      }

      /* RRD header is ready. Start writing to the file. */

      fwrite(rrd->stat_head, sizeof(stat_head_t), 1, fh);
      fwrite(rrd->ds_def, sizeof(ds_def_t), n_ds, fh);
      fwrite(rrd->rra_def, sizeof(rra_def_t), n_rra, fh);
      fwrite(rrd->live_head, sizeof(live_head_t), 1, fh);
      fwrite(rrd->pdp_prep, sizeof(pdp_prep_t), n_ds, fh);
      fwrite(rrd->cdp_prep, sizeof(cdp_prep_t), n_rra * n_ds, fh);
      fwrite(rrd->rra_ptr, sizeof(rra_ptr_t), n_rra, fh);

      /* write CDP values. cur_row points somewhere in the middle of the
       * RRA on the disk, but we write it sequentially */

      for (i = 0; i < n_rra; i++) {
          unsigned long num_rows = rrd->rra_def[i].row_cnt;
          unsigned long disk_start_row = rrd->rra_ptr[i].cur_row;
          unsigned long mem_cur_row = num_rows - disk_start_row - 1;
          AV *rra_cdp_data_array;

          /* get $self->{cdp_data}[$i] */
          fetch_result = av_fetch(cdp_data_array, i, 0);
          rra_cdp_data_array = (AV *)SvRV(*fetch_result);

          for (ii = 0; ii < num_rows; ii++) {
              AV *row_cdp_data;

              if (mem_cur_row >= num_rows) {
                  mem_cur_row = 0;
              }

              fetch_result = av_fetch(rra_cdp_data_array, mem_cur_row, 0);
              row_cdp_data = (AV *)SvRV(*fetch_result);

              for (iii = 0; iii < n_ds; iii++) {
                  fetch_result = av_fetch(row_cdp_data, iii, 0);
                  row_buf[iii] = SvNV(*fetch_result);
              }

              fwrite(row_buf, sizeof(rrd_value_t), n_ds, fh);
              mem_cur_row++;
          }
      }

      /* lets see if we had an error */
      if (ferror(fh)) {
          local_rrd_free(rrd);
          free(row_buf);
          croak("Error while writing '%s': %s", filename, strerror(errno));
          fclose(fh);
      }

      fclose(fh);
      local_rrd_free(rrd);
      free(row_buf);
  }



#  Emacs formatting hints
#
#  Local Variables:
#  mode: c
#  indent-tabs-mode: nil
#  End:

