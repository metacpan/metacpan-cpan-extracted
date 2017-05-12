#include <stdlib.h>
#include <string.h>

#include "EXTERN.h"
#include "perl.h"

#include "sort.h"

/* basic comparison operators */
int compare_int(const ElementType *a, const ElementType *b) {
        return (a->i < b->i ? -1 : (a->i > b->i ? 1 : 0));
}

int compare_str(const ElementType *a, const ElementType *b) {
	return strcmp(a->s, b->s);
}

/*
  A > B
  cmp(A, B) > 0
*/

/* sorting methods */
void Swap(ElementType *Lhs, ElementType *Rhs) {
	ElementType Tmp = *Lhs;
	*Lhs = *Rhs;
	*Rhs = Tmp;
}

void InsertionSort(ElementType A[], int N, CmpFunction *cmp) {
	int j, P;
	ElementType Tmp;

	for (P = 1; P < N; P++) {
		Tmp = A[P];
		for (j = P; j > 0 && (*cmp)(&A[j - 1], &Tmp) > 0; j--)
			A[j] = A[j - 1];
		A[j] = Tmp;
	}
}

void ShellSort(ElementType A[], int N, CmpFunction *cmp) {
	int i, j, Increment;
	ElementType Tmp;

	for (Increment = N / 2; Increment > 0; Increment /= 2)
		for (i = Increment; i < N; i++) {
			Tmp = A[i];
			for (j = i; j >= Increment; j -= Increment)
				if ((*cmp)(&A[j - Increment], &Tmp) >= 0)
					A[j] = A[j - Increment];
				else
					break;
			A[j] = Tmp;
		}
}

/* Heap */

#define LeftChild( i )  ( 2 * ( i ) + 1 )

void PercDown(ElementType A[], int i, int N, CmpFunction *cmp) {
	int Child;
	ElementType Tmp;

	for (Tmp = A[i]; LeftChild( i ) < N; i = Child) {
		Child = LeftChild( i );
		if (Child != N - 1 && (*cmp)(&A[Child + 1], &A[Child]) > 0)
			Child++;
		if ((*cmp)(&A[Child], &Tmp) > 0)
			A[i] = A[Child];
		else
			break;
	}
	A[i] = Tmp;
}

void VoidSort(ElementType A[], int N, CmpFunction *cmp) {
	ElementType i;
	i = A[0];
}

void HeapSort(ElementType A[], int N, CmpFunction *cmp) {
	int i;

	for (i = N / 2; i >= 0; i--) /* BuildHeap */
		PercDown(A, i, N, cmp);
	for (i = N - 1; i > 0; i--) {
		Swap(&A[0], &A[i]); /* DeleteMax */
		PercDown(A, 0, i, cmp);
	}
}

/* Merge */

void Merge(ElementType A[], ElementType TmpArray[], int Lpos, int Rpos,
		int RightEnd, CmpFunction *cmp) {
	int i, LeftEnd, NumElements, TmpPos;

	LeftEnd = Rpos - 1;
	TmpPos = Lpos;
	NumElements = RightEnd - Lpos + 1;

	/* main loop */
	while (Lpos <= LeftEnd && Rpos <= RightEnd)
		if ((*cmp)(&A[Rpos], &A[Lpos]) >= 0)
			TmpArray[TmpPos++] = A[Lpos++];
		else
			TmpArray[TmpPos++] = A[Rpos++];

	while (Lpos <= LeftEnd) /* Copy rest of first half */
		TmpArray[TmpPos++] = A[Lpos++];
	while (Rpos <= RightEnd) /* Copy rest of second half */
		TmpArray[TmpPos++] = A[Rpos++];

	/* Copy TmpArray back */
	for (i = 0; i < NumElements; i++, RightEnd--)
		A[RightEnd] = TmpArray[RightEnd];
}

void MSort(ElementType A[], ElementType TmpArray[], int Left, int Right, CmpFunction *cmp) {
	int Center;

	if (Left < Right) {
		Center = (Left + Right) / 2;
		MSort(A, TmpArray, Left, Center, cmp);
		MSort(A, TmpArray, Center + 1, Right, cmp);
		Merge(A, TmpArray, Left, Center + 1, Right, cmp);
	}
}

void MergeSort(ElementType A[], int N, CmpFunction *cmp) {
	ElementType *TmpArray;

	/* WTF : need to be improved !!! FIXME do sort in place */
	TmpArray = malloc(N * sizeof(ElementType));
	if (TmpArray != NULL) {
		MSort(A, TmpArray, 0, N - 1, cmp);
		free(TmpArray);
	} else
		return;

	/*	croak("No space for tmp array!!!"); */
}

/* Quick Sort */
/* Return median of Left, Center, and Right */
/* Order these and hide the pivot */

ElementType Median3(ElementType A[], int Left, int Right, CmpFunction *cmp) {
	int Center = (Left + Right) / 2;

	if ((*cmp)(&A[Left], &A[Center]) > 0)
		Swap(&A[Left], &A[Center]);
	if ((*cmp)(&A[Left], &A[Right]) > 0)
		Swap(&A[Left], &A[Right]);
	if ((*cmp)(&A[Center], &A[Right]) > 0)
		Swap(&A[Center], &A[Right]);

	/* Invariant: A[ Left ] <= A[ Center ] <= A[ Right ] */

	Swap(&A[Center], &A[Right - 1]); /* Hide pivot */
	return A[Right - 1]; /* Return pivot */
}

#define Cutoff ( 3 )

void Qsort(ElementType A[], int Left, int Right, CmpFunction *cmp) {
	int i, j;
	ElementType Pivot;

	if (Left + Cutoff <= Right) {
		Pivot = Median3(A, Left, Right, cmp);
		i = Left;
		j = Right - 1;
		for (;;) {
			while ((*cmp)(&Pivot, &A[++i]) > 0) {}
			while ((*cmp)(&A[--j], &Pivot) > 0) {}
			if (i < j)
				Swap(&A[i], &A[j]);
			else
				break;
		}
		Swap(&A[i], &A[Right - 1]); /* Restore pivot */

		Qsort(A, Left, i - 1, cmp);
		Qsort(A, i + 1, Right, cmp);
	} else
		/* Do an insertion sort on the subarray */
		InsertionSort( A + Left, Right - Left + 1, cmp);

}

void QuickSort(ElementType A[], int N, CmpFunction *cmp) {
	Qsort(A, 0, N - 1, cmp);
}

/* Places the kth smallest element in the kth position */
/* Because arrays start at 0, this will be index k-1 */
void Qselect(ElementType A[], int k, int Left, int Right, CmpFunction *cmp) {
	int i, j;
	ElementType Pivot;

	if (Left + Cutoff <= Right) {
		Pivot = Median3(A, Left, Right, cmp);
		i = Left;
		j = Right - 1;
		for (;;) {
			while ((*cmp)(&Pivot, &A[++i]) > 0) {}
			while ((*cmp)(&A[--j], &Pivot) > 0) {}
			if (i < j)
				Swap(&A[i], &A[j]);
			else
				break;
		}
		Swap(&A[i], &A[Right - 1]); /* Restore pivot */

		if (k <= i)
			Qselect(A, k, Left, i - 1, cmp);
		else if (k > i + 1)
			Qselect(A, k, i + 1, Right, cmp);
	} else
		InsertionSort(A + Left, Right - Left + 1, cmp);
}

/*
 int main( int argc, char *argv[] )
 {
 ElementType test[5];
 test[0].i = 5;
 test[1].i = 3;
 test[2].i = 4;
 test[3].i = 8;
 test[4].i = 1;

 InsertionSort(test, 5, compare_int);

 int i;
 for (i = 0; i < 5; ++i) {
 printf("%02d -> %d\n", i, test[i].i);
 }


 int tab[10];
 int *oth;

 for (i = 0; i < 10; ++i) {
	 tab[i] = i + 1;
 }

 for (i = 0; i < 10; ++i) {
	 printf("before i[%d] = %d\n", i, tab[i]);
 }

 oth = (int *) tab + 5;

 for (i = 0; i < 10; ++i) {
	 printf("after i[%d] = %d\n", i, oth[i]);
 }

 char ctab[10];
 char *coth;

 for (i = 0; i < 10; ++i) {
	 ctab[i] = 'a' + i;
 }

 for (i = 0; i < 10; ++i) {
	 printf("before c[%d] = %c\n", i, ctab[i]);
 }

 coth = (char *) ctab + 5;

 for (i = 0; i < 10; ++i) {
	 printf("after c[%d] = %c\n", i, coth[i]);
 }



 ElementType a;
 ElementType b;

 a.i = 42;
 b.i = 51;

 printf("a > b %d\n", compare_int(&a, &b));
 printf("a > a %d\n", compare_int(&a, &a));
 printf("b > a %d\n", compare_int(&b, &a));

  a.s = "abcdef";
  b.s = "xyz";

  printf("S a > b %d\n", compare_str(&a, &b));
  printf("S a > a %d\n", compare_str(&a, &a));
  printf("S b > a %d\n", compare_str(&b, &a));


 }

 */
