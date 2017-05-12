! --------------------------------------------------------------------
!    This program uses Heron's formula to compute the area of a
! triangle.  It "contains" the following functions;
!    (1)  LOGICAL function TriangleTest() -
!         this function has three real formal arguments and tests
!         to see if they can form a triangle.  If they do form a
!         triangle, this function returns .TRUE.; otherwise, it
!         returns .FALSE.
!    (2)  REAL function TriangleArea() -
!         this functions has three real formal arguments considered
!         as three sides of a triangle and returns the area of this
!         triangle.
! --------------------------------------------------------------------

PROGRAM  HeronFormula
   IMPLICIT  NONE

   REAL :: a, b, c, TriangleArea

   DO
      WRITE(*,*)  'Three sides of a triangle please --> '
      READ(*,*)   a, b, c
      WRITE(*,*)  'Input sides are ', a, b, c
      IF (TriangleTest(a, b, c))  EXIT  ! exit if not a triangle
      WRITE(*,*)  'Your input CANNOT form a triangle.  Try again'
   END DO

   TriangleArea = Area(a, b, c)
   WRITE(*,*)  'Triangle area is ', TriangleArea

CONTAINS

! --------------------------------------------------------------------
! LOGICAL FUNCTION  TriangleTest() :
!    This function receives three REAL numbers and tests if they form
! a triangle by testing:
!    (1)  all arguments must be positive, and
!    (2)  the sum of any two is greater than the third
! If the arguments form a triangle, this function returns .TRUE.;
! otherwise, it returns .FALSE.
! --------------------------------------------------------------------
   
   LOGICAL FUNCTION  TriangleTest(a, b, c)
      IMPLICIT  NONE

      REAL, INTENT(IN) :: a, b, c
      LOGICAL          :: test1, test2

      test1 = (a > 0.0) .AND. (b > 0.0) .AND. (c > 0.0)
      test2 = (a + b > c) .AND. (a + c > b) .AND. (b + c > a)
      TriangleTest = test1 .AND. test2  ! both must be .TRUE.
   END FUNCTION  TriangleTest

! --------------------------------------------------------------------
! REAL FUNCTION  Area() :
!    This function takes three real number that form a triangle, and
! computes and returns the area of this triangle using Heron's formula.
! --------------------------------------------------------------------

   REAL FUNCTION  Area(a, b, c)
      IMPLICIT  NONE

      REAL, INTENT(IN) :: a, b, c
      REAL             :: s

      s    = (a + b + c) / 2.0
      Area = SQRT(s*(s-a)*(s-b)*(s-c))
   END FUNCTION  Area

END PROGRAM  HeronFormula
