/* This code copied from docs. It was broken.
   I fixed it a bit.
*/
static char *mxclass[16] = {"cell", "struct", "object","char","sparse",
                            "double","single","int8", "uint8","int16","uint16",
                            "int32","uint32","int64","uint64","function"
};
void extra_matio_print_all_var_info_clumsy(mat_t * matfp) {
  matvar_t *matvar;
  size_t    nbytes;
  int       i;
  char size[32] = {' ',};
  fflush(stdout);
  printf( "%-20s       %-10s     %-10s     %-18s\n", "Name", "Size", "Bytes", "Class");
  while ( NULL != (matvar = Mat_VarReadNextInfo(matfp)) ) {
    printf("%-20s", matvar->name);
    if ( matvar->rank > 0 ) {
      int cnt = 0;
      printf("%8zd", matvar->dims[0]);
      for ( i = 1; i < matvar->rank; i++ ) {
        if ( ceil(log10(matvar->dims[i]))+1 < 32 )
          cnt += sprintf(size+cnt,"x%zd", matvar->dims[i]);
      }
      printf("%-10s",size);
    } else {
      printf("                    ");
    }
    nbytes = Mat_VarGetSize(matvar);
    printf("  %8zd",nbytes);
    printf("         %-18s\n",mxclass[matvar->class_type-1]);
    Mat_VarPrint(matvar,0);
    Mat_VarFree(matvar);
  }
  fflush(stdout);
}


/* 
   This one is simpler ! 
*/

void extra_matio_print_all_var_info (mat_t * matfp, int printdata) {
  matvar_t *matvar;
  fflush(stdout);
  if (printdata)
    while ( NULL != (matvar = Mat_VarReadNext(matfp)) ) {
      Mat_VarPrint(matvar,printdata);
      Mat_VarFree(matvar);
    }
  else 
    while ( NULL != (matvar = Mat_VarReadNextInfo(matfp)) ) {
      Mat_VarPrint(matvar,printdata);
      Mat_VarFree(matvar);
    }
  fflush(stdout);
}


/* broken */
/*
void extra_matio_print_all_var_info_new (mat_t * matfp, int printdata,
                                     int max_cols, int max_rows) {
  matvar_t *matvar;
  fflush(stdout);
  if (printdata)
    while ( NULL != (matvar = Mat_VarReadNext(matfp)) ) {
      Mat_VarPrint2(matvar,printdata,max_cols,max_rows);
      Mat_VarFree(matvar);
    }
  else 
    while ( NULL != (matvar = Mat_VarReadNextInfo(matfp)) ) {
      Mat_VarPrint2(matvar,printdata,max_cols,max_rows);
      Mat_VarFree(matvar);
    }
  fflush(stdout);
}
*/
