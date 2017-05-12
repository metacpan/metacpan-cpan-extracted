EXE = $(patsubst %.cpp,%.o, $(wildcard *.cpp))
CXXFLAGS += -I.

all: $(EXE)

%.o: %.cc
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)

