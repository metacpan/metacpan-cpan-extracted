#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <math.h>

#define HOW_MANY 18 
#define NK 10 

int main(int argc, char ** argv) 
{
		int i;
		int k;
		int rank;
		double * dat;
		double start_time;
		int sizes[HOW_MANY];
		int size;
		double time[HOW_MANY][NK];
		MPI_Status s;

		MPI_Init(&argc,&argv);
		MPI_Comm_rank(MPI_COMM_WORLD,&rank);
		MPI_Comm_size(MPI_COMM_WORLD,&size);

		if (size != 2) exit(7);
		for (k=0;k<HOW_MANY;k++){ sizes[k]=pow(2,k); }
		dat = malloc(  (sizeof (double)) * pow(2,HOW_MANY)   );
		for (i=0;i<NK;i++) 
		{
			for (k=0;k<HOW_MANY;k++)
			{
				size=sizes[k];
				MPI_Barrier(MPI_COMM_WORLD);
				start_time = MPI_Wtime();
				if (rank == 1) MPI_Send(dat,size,MPI_DOUBLE,0,0,MPI_COMM_WORLD);
				if (rank == 0) MPI_Recv(dat,size,MPI_DOUBLE,1,0,MPI_COMM_WORLD, &s);
				time[k][i] = MPI_Wtime() - start_time;
			}
		}

		if (rank == 0) {
			for (k=0;k<HOW_MANY;k++)
			{
				for (i=0;i<NK;i++) 
				{
					printf("%f ", time[k][i]);
				}
				printf("\n");
			}
		}

		if (rank == 1) MPI_Send(time,HOW_MANY * NK,MPI_DOUBLE,0,0,MPI_COMM_WORLD);
		if (rank == 0) MPI_Recv(time,HOW_MANY * NK,MPI_DOUBLE,1,0,MPI_COMM_WORLD, &s);

		MPI_Barrier(MPI_COMM_WORLD);
		if (rank == 0) {
			printf("\n");
			for (k=0;k<HOW_MANY;k++)
			{
				for (i=0;i<NK;i++) 
				{
					printf("%f ", time[k][i]);
				}
				printf("\n");
			}
		}



		MPI_Finalize();
}
