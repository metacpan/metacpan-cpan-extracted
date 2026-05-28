"""Golden fixture: parameterized generic types — list, dict, tuple."""

from typing import Dict, List, Tuple


class Store:
    def put(self, key: str, value: dict[str, int]) -> None:
        ...

    def query(self, filters: Dict[str, List[int]]) -> List[Tuple[str, int]]:
        ...
