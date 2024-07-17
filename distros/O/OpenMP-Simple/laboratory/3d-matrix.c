#include <stdio.h>
#include <omp.h>

#define SIZE 3

void multiply_matrices(int A[SIZE][SIZE][SIZE], int B[SIZE][SIZE][SIZE], int C[SIZE][SIZE][SIZE]) {
    #pragma omp parallel for collapse(3)
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            for (int k = 0; k < SIZE; k++) {
                C[i][j][k] = 0;
                for (int l = 0; l < SIZE; l++) {
                    C[i][j][k] += A[i][j][l] * B[i][l][k];
                }
            }
        }
    }
}

int main() {
    int A[SIZE][SIZE][SIZE] = {
        {{1, 2, 3},    {4, 5, 6},    {7, 8, 9}},
        {{10, 11, 12}, {13, 14, 15}, {16, 17, 18}},
        {{19, 20, 21}, {22, 23, 24}, {25, 26, 27}}
    };

    int B[SIZE][SIZE][SIZE] = {
        {{1, 1, 1}, {1, 1, 1}, {1, 1, 1}},
        {{2, 2, 2}, {2, 2, 2}, {2, 2, 2}},
        {{3, 3, 3}, {3, 3, 3}, {3, 3, 3}}
    };

    int C[SIZE][SIZE][SIZE];

    multiply_matrices(A, B, C);

    printf("Resulting Matrix C:\n");
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            for (int k = 0; k < SIZE; k++) {
                printf("%d ", C[i][j][k]);
            }
            printf("\n");
        }
        printf("\n");
    }

    return 0;
}

