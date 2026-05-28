"""Golden fixture: parameter referencing another class in the fixture."""


class Result:
    pass


class Engine:
    def run(self, target: Result) -> Result:
        return target
